defmodule Kalends.DateTime do
  @moduledoc """
  DateTime provides a struct which represents a certain time and date in a
  certain time zone.
  
  DateTime can also represent a "naive time". That is a point in time without
  a specified time zone.

  The functions in this module can be used to create and manipulate
  DateTime structs.
  """
  require Kalends.TimeZoneData
  require Kalends.TimeZonePeriods
  alias Kalends.TimeZoneData, as: TimeZoneData
  alias Kalends.TimeZonePeriods, as: TimeZonePeriods

  defstruct [:year, :month, :date, :hour, :min, :sec, :timezone, :abbr, :ambiguous, :utc_off, :std_off]

  defp now_utc do
    from_erl!(:erlang.universaltime, "UTC", "UTC", 0, 0)
  end

  @doc """
  Takes a timezone name a returns a DateTime with the current time in
  that timezone. Timezone names must be in the TZ data format.

  Usually the list will only have a size of 1. But if for instance there is a
  shift from DST to winter time taking place, the list will have 2 elements.

  ## Examples
  iex > Kalends.DateTime.now "UTC"
      %Kalends.DateTime{abbr: "UTC", ambiguous: {false, nil}, date: 15, hour: 2,
       min: 39, month: 10, sec: 53, std_off: 0, timezone: "UTC", utc_off: 0,
       year: 2014}
  iex > Kalends.DateTime.now "Europe/Copenhagen"
      %Kalends.DateTime{abbr: "CEST", ambiguous: {false, nil}, date: 15, hour: 4,
       min: 41, month: 10, sec: 1, std_off: 3600, timezone: "Europe/Copenhagen",
       utc_off: 3600, year: 2014}
  """
  def now("UTC"), do: now_utc
  def now(timezone) do
    now_utc_secs = now_utc |> gregorian_seconds
    period_list = TimeZonePeriods.periods_for_time(timezone, now_utc_secs, :utc)
    period = hd period_list
    now_utc_secs + period.utc_off + period.std_off
    |>from_gregorian_seconds!(timezone, period.zone_abbr, period.utc_off, period.std_off)
  end

  @doc """
  Takes a DateTime and the name of a new timezone.
  The DateTime must be unambiguous.
  Returns a DateTime with the equivalent time in the new timezone.

  Make sure that date_time is unambiguous and that timezone is valid.

  ## Example
    iex> {:ok, nyc} = from_erl {{2014,10,2},{0,29,10}},"America/New_York"; shift_zone!(nyc, "Europe/Copenhagen")
    %Kalends.DateTime{abbr: "CEST", ambiguous: {false, nil}, date: 2, hour: 6, min: 29, month: 10, sec: 10, timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 2014}
  """
  def shift_zone!(date_time, timezone) do
    date_time
    |>shift_to_utc
    |>shift_from_utc(timezone)
  end

  defp shift_to_utc(date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
    period_list = TimeZonePeriods.periods_for_time(date_time.timezone, greg_secs, :wall)
    period = period_list|>hd
    greg_secs-period.utc_off-period.std_off
    |>from_gregorian_seconds!("UTC", "UTC", 0, 0)
  end

  defp shift_from_utc(utc_date_time, to_timezone) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(utc_date_time|>to_erl)
    period_list = TimeZonePeriods.periods_for_time(to_timezone, greg_secs, :utc)
    period = period_list|>hd
    greg_secs+period.utc_off+period.std_off
    |>from_gregorian_seconds!(to_timezone, period.zone_abbr, period.utc_off, period.std_off)
  end

  # Takes gregorian seconds and and optional timezone.
  # Returns a DateTime.

  # ## Examples
  #   iex> from_gregorian_seconds!(63578970620)
  #   %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: nil, year: 2014}
  #   iex> from_gregorian_seconds!(63578970620, "America/Montevideo")
  #   %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: "America/Montevideo", year: 2014}
  defp from_gregorian_seconds!(gregorian_seconds, timezone, abbr, utc_off, std_off) do
    gregorian_seconds
    |>:calendar.gregorian_seconds_to_datetime
    |>from_erl!(timezone, abbr, utc_off, std_off)
  end

  @doc """
  Takes an Erlang-style date-time tuple.
  If the datetime is valid it returns a tuple with a tag and a naive DateTime.
  Naive in this context means that it does not have any timezone data.

  ## Examples
    iex from_erl({{2014, 9, 26}, {17, 10, 20}})
        {:ok, %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014, timezone: nil, abbr: nil, ambiguous: nil} }

    iex from_erl({{2014, 99, 99}, {17, 10, 20}})
        {:error, :invalid_datetime}
  """
  def from_erl(date_time), do: from_erl_naive(date_time)
  @doc """
  Takes an Erlang-style date-time tuple and additionally a timezone name.
  Returns a tuple with a tag and a DateTime struct.

  The tag can be :ok, :ambiguous or :error. :ok is for an unambigous time.
  :ambiguous is for a time that could be two different times - usually either
  summer or winter time. See the examples below.

  An erlang style date-time tuple has the following format:
  {{year, month, date}, {hour, minute, second}}

  ## Examples
    Normal, non-ambigous time
    iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
    {:ok, %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20,
                            year: 2014, timezone: "America/Montevideo",
                            abbr: "UYT", ambiguous: {false, nil},
                            utc_off: -10800, std_off: 0} }

    Switching from summer to wintertime in the fall means an ambigous time.
    The ambiguous field will be a list of tuples with zone abbreviation,
    UTC offset in seconds, standard offset in seconds.
    iex> from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo")
    {:ambiguous, %Kalends.DateTime{date: 9, hour: 1, min: 1, month: 3, sec: 1, year: 2014, timezone: "America/Montevideo", abbr: nil,
     ambiguous: {true, [{"UYST", -10800, 3600}, {"UYT", -10800, 0}]}} }

    iex from_erl({{2014, 9, 26}, {17, 10, 20}}, "Non-existing timezone")
        {:error, :timezone_not_found}

    The time between 2:00 and 3:00 does not exist because of the gap caused
    by switching to DST.

    iex from_erl({{2014, 3, 30}, {2, 20, 02}}, "Europe/Copenhagen")
        {:error, :invalid_datetime_for_timezone}

  """
  def from_erl(date_time, timezone) do
    validity = validate_erl_datetime date_time
    from_erl_validity(date_time, timezone, validity)
  end

  # Date, time and timezone. Date and time is valid.
  defp from_erl_validity(datetime, timezone, true) do
    # validate that timezone exists
    from_erl_timezone_validity(datetime, timezone, TimeZoneData.zone_exists?(timezone))
  end
  defp from_erl_validity(_, _, false) do
    {:error, :invalid_datetime}
  end

  defp from_erl_timezone_validity(_, _, false), do: {:error, :timezone_not_found}

  defp from_erl_timezone_validity({date, time}, timezone, true) do
    # get periods for time
    greg_secs = :calendar.datetime_to_gregorian_seconds({date, time})
    periods = TimeZonePeriods.periods_for_time(timezone, greg_secs, :wall)
    from_erl_periods({date, time}, timezone, periods)
  end

  defp from_erl_periods(_, _, periods) when periods == [] do
    {:error, :invalid_datetime_for_timezone}
  end
  defp from_erl_periods({{year, month, date}, {hour, min, sec}}, timezone, periods) when length(periods) == 1 do
    period = periods |> hd
    {:ok, %Kalends.DateTime{year: year, month: month, date: date, hour: hour,
         min: min, sec: sec, timezone: timezone, abbr: period.zone_abbr,
         ambiguous: {false, nil}, utc_off: period.utc_off, std_off: period.std_off } }
  end
  # When a time is ambigous (for instance switching from summer- to winter-time)
  defp from_erl_periods({{year, month, date}, {hour, min, sec}}, timezone, periods) when length(periods) == 2 do
    abbreviations = periods
                    |> Enum.map(fn period -> {period.zone_abbr, period.utc_off, period.std_off} end)
                    # sort by the first element - zone abbreviation
                    |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
    {:ambiguous, %Kalends.DateTime{year: year, month: month, date: date, hour: hour, min: min, sec: sec, timezone: timezone, abbr: nil, ambiguous: {true, abbreviations}} }
  end

  defp from_erl_naive({{year, month, date}, {hour, min, sec}}) do
    if validate_erl_datetime {{year, month, date}, {hour, min, sec}} do
      {:ok, %Kalends.DateTime{year: year, month: month, date: date, hour: hour, min: min, sec: sec} }
    else
      {:error, :invalid_datetime}
    end
  end

  defp from_erl!({{year, month, date}, {hour, min, sec}}, timezone, abbr, utc_off, std_off) do
    %Kalends.DateTime{year: year, month: month, date: date, hour: hour, min: min, sec: sec, timezone: timezone, abbr: abbr, utc_off: utc_off, std_off: std_off, ambiguous: {false, nil}}
  end

  @doc """
  Takes a DateTime struct and returns an erlang style datetime tuple.

  ## Examples

    iex > Kalends.DateTime.now("UTC") |> Kalends.DateTime.to_erl
        {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%Kalends.DateTime{year: year, month: month, date: date, hour: hour, min: min, sec: sec}) do
    {{year, month, date}, {hour, min, sec}}
  end

  @doc """
  Takes a DateTime and returns an integer of gregorian seconds starting with
  year 0. This is done via the Erlang calendar module.

    iex> elem(from_erl({{2014,9,26},{17,10,20}}),1) |> gregorian_seconds
    63578970620
  """
  def gregorian_seconds(date_time) do
    :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
  end

  defp validate_erl_datetime({date, _}) do
    :calendar.valid_date date
  end
end
