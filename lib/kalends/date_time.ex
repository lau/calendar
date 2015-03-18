defmodule Kalends.DateTime do
  @moduledoc """
  DateTime provides a struct which represents a certain time and date in a
  certain time zone.

  The functions in this module can be used to create and transform
  DateTime structs.
  """
  alias Kalends.TimeZoneData
  require Kalends.Date
  require Kalends.Time

  defstruct [:year, :month, :day, :hour, :min, :sec, :usec, :timezone, :abbr, :utc_off, :std_off]

  @doc """
  Like DateTime.now("Etc/UTC")
  """
  def now_utc do
    erl_timestamp = :os.timestamp
    {_, _, usec} = erl_timestamp
    erl_timestamp
    |> :calendar.now_to_datetime
    |> from_erl!("Etc/UTC", "UTC", 0, 0, usec)
  end

  @doc """
  Takes a timezone name a returns a DateTime with the current time in
  that timezone. Timezone names must be in the TZ data format.

  ## Examples

      iex > DateTime.now "UTC"
      %Kalends.DateTime{abbr: "UTC", day: 15, hour: 2,
       min: 39, month: 10, sec: 53, std_off: 0, timezone: "UTC", utc_off: 0,
       year: 2014}

      iex > DateTime.now "Europe/Copenhagen"
      %Kalends.DateTime{abbr: "CEST", day: 15, hour: 4,
       min: 41, month: 10, sec: 1, std_off: 3600, timezone: "Europe/Copenhagen",
       utc_off: 3600, year: 2014}
  """
  def now("Etc/UTC"), do: now_utc
  def now(timezone) do
    {now_utc_secs, usec} = now_utc |> gregorian_seconds_and_usec
    period_list = TimeZoneData.periods_for_time(timezone, now_utc_secs, :utc)
    period = hd period_list
    now_utc_secs + period.utc_off + period.std_off
    |>from_gregorian_seconds!(timezone, period.zone_abbr, period.utc_off, period.std_off, usec)
  end

  @doc """
  Like shift_zone without "!", but does not check that the time zone is valid
  and just returns a DateTime struct instead of a tuple with a tag.

  ## Example

      iex> from_erl!({{2014,10,2},{0,29,10}},"America/New_York") |> shift_zone! "Europe/Copenhagen"
      %Kalends.DateTime{abbr: "CEST", day: 2, hour: 6, min: 29, month: 10, sec: 10,
                        timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 2014}

  """
  def shift_zone!(date_time, timezone) do
    date_time
    |>shift_to_utc
    |>shift_from_utc(timezone)
  end

  @doc """
  Takes a DateTime and the name of a new timezone.
  Returns a DateTime with the equivalent time in the new timezone.

  ## Example

      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York",123456) |> shift_zone("Europe/Copenhagen")
      {:ok, %Kalends.DateTime{abbr: "CEST", day: 2, hour: 6, min: 29, month: 10, sec: 10, timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 2014, usec: 123456}}

      iex> {:ok, nyc} = from_erl {{2014,10,2},{0,29,10}},"America/New_York"; shift_zone(nyc, "Invalid timezone")
      {:invalid_time_zone, nil}
  """
  def shift_zone(date_time, timezone) do
    if TimeZoneData.zone_exists?(timezone) do
      {:ok, shift_zone!(date_time, timezone)}
    else
      {:invalid_time_zone, nil}
    end
  end

  defp shift_to_utc(date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
    period_list = TimeZoneData.periods_for_time(date_time.timezone, greg_secs, :wall)
    period = period_by_offset(period_list, date_time.utc_off, date_time.std_off)
    greg_secs-period.utc_off-period.std_off
    |>from_gregorian_seconds!("Etc/UTC", "UTC", 0, 0, date_time.usec)
  end

  # When we have a list of 2 periods, return the one where UTC offset
  # and standard offset matches. The is used for instance during ambigous
  # wall time in the fall when switching back from summer time to standard
  # time.
  # If there is just one period, just return the only period in the list
  defp period_by_offset(period_list, _utc_off, _std_off) when length(period_list) == 1 do
    hd(period_list)
  end
  defp period_by_offset(period_list, utc_off, std_off) do
    matching = period_list |> Enum.filter(&(&1.utc_off == utc_off && &1.std_off == std_off))
    hd(matching)
  end

  defp shift_from_utc(utc_date_time, to_timezone) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(utc_date_time|>to_erl)
    period_list = TimeZoneData.periods_for_time(to_timezone, greg_secs, :utc)
    period = period_list|>hd
    greg_secs+period.utc_off+period.std_off
    |>from_gregorian_seconds!(to_timezone, period.zone_abbr, period.utc_off, period.std_off, utc_date_time.usec)
  end

  # Takes gregorian seconds and and optional timezone.
  # Returns a DateTime.

  # ## Examples
  #   iex> from_gregorian_seconds!(63578970620)
  #   %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: nil, year: 2014}
  #   iex> from_gregorian_seconds!(63578970620, "America/Montevideo")
  #   %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: "America/Montevideo", year: 2014}
  defp from_gregorian_seconds!(gregorian_seconds, timezone, abbr, utc_off, std_off, usec) do
    gregorian_seconds
    |>:calendar.gregorian_seconds_to_datetime
    |>from_erl!(timezone, abbr, utc_off, std_off, usec)
  end

  @doc """
  Like from_erl/2 without "!", but returns the result directly without a tag.
  Will raise if date is ambiguous or invalid! Only use this if you are sure
  the date is valid. Otherwise use "from_erl" without the "!".

  Example:

      iex> from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
      %Kalends.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014, timezone: "America/Montevideo", abbr: "UYT", utc_off: -10800, std_off: 0}
  """
  def from_erl!(date_time, time_zone, usec \\ nil) do
    {:ok, result} = from_erl(date_time, time_zone, usec)
    result
  end

  @doc """
  Takes an Erlang-style date-time tuple and additionally a timezone name.
  Returns a tuple with a tag and a DateTime struct.

  The tag can be :ok, :ambiguous or :error. :ok is for an unambigous time.
  :ambiguous is for a time that could have different UTC offsets and/or
  standard offsets. Usually when switching from summer to winter time.

  An erlang style date-time tuple has the following format:
  {{year, month, day}, {hour, minute, second}}

  ## Examples

    Normal, non-ambigous time

      iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
      {:ok, %Kalends.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: nil} }

    Switching from summer to wintertime in the fall means an ambigous time.

      iex> from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo")
      {:ambiguous, %Kalends.AmbiguousDateTime{possible_date_times:
        [%Kalends.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
                           year: 2014, timezone: "America/Montevideo",
                           abbr: "UYST", utc_off: -10800, std_off: 3600},
         %Kalends.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
                           year: 2014, timezone: "America/Montevideo",
                           abbr: "UYT", utc_off: -10800, std_off: 0},
        ]}
      }

      iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "Non-existing timezone")
      {:error, :timezone_not_found}

    The time between 2:00 and 3:00 in the following example does not exist
    because of the one hour gap caused by switching to DST.

      iex> from_erl({{2014, 3, 30}, {2, 20, 02}}, "Europe/Copenhagen")
      {:error, :invalid_datetime_for_timezone}

    Time with fractional seconds. This represents the time 17:10:20.987654321

      iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo", 987654)
      {:ok, %Kalends.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: 987654} }

  """
  def from_erl(date_time, timezone, usec \\ nil) do
    validity = validate_erl_datetime date_time
    from_erl_validity(date_time, timezone, validity, usec)
  end

  # Date, time and timezone. Date and time is valid.
  defp from_erl_validity(datetime, timezone, true, usec) do
    # validate that timezone exists
    from_erl_timezone_validity(datetime, timezone, TimeZoneData.zone_exists?(timezone), usec)
  end
  defp from_erl_validity(_, _, false, _) do
    {:error, :invalid_datetime}
  end

  defp from_erl_timezone_validity(_, _, false, _), do: {:error, :timezone_not_found}

  defp from_erl_timezone_validity({date, time}, timezone, true, usec) do
    # get periods for time
    greg_secs = :calendar.datetime_to_gregorian_seconds({date, time})
    periods = TimeZoneData.periods_for_time(timezone, greg_secs, :wall)
    from_erl_periods({date, time}, timezone, periods, usec)
  end

  defp from_erl_periods(_, _, periods, _) when periods == [] do
    {:error, :invalid_datetime_for_timezone}
  end
  defp from_erl_periods({{year, month, day}, {hour, min, sec}}, timezone, periods, usec) when length(periods) == 1 do
    period = periods |> hd
    {:ok, %Kalends.DateTime{year: year, month: month, day: day, hour: hour,
         min: min, sec: sec, timezone: timezone, abbr: period.zone_abbr,
         utc_off: period.utc_off, std_off: period.std_off, usec: usec } }
  end
  # When a time is ambigous (for instance switching from summer- to winter-time)
  defp from_erl_periods({{year, month, day}, {hour, min, sec}}, timezone, periods, usec) when length(periods) == 2 do
    possible_date_times =
    Enum.map(periods, fn period ->
           %Kalends.DateTime{year: year, month: month, day: day, hour: hour,
           min: min, sec: sec, timezone: timezone, abbr: period.zone_abbr,
           utc_off: period.utc_off, std_off: period.std_off, usec: usec }
       end )
    # sort by abbreviation
    |> Enum.sort(fn dt1, dt2 -> dt1.abbr <= dt2.abbr end)

    {:ambiguous, %Kalends.AmbiguousDateTime{ possible_date_times: possible_date_times} }
  end

  defp from_erl!({{year, month, day}, {hour, min, sec}}, timezone, abbr, utc_off, std_off, usec) do
    %Kalends.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, timezone: timezone, abbr: abbr, utc_off: utc_off, std_off: std_off, usec: usec}
  end

  @doc """
  Like from_erl, but also takes an argument with the total UTC offset.
  (Total offset is standard offset + UTC offset)

  The result will be the same as from_erl, except if the datetime is ambiguous.
  When the datetime is ambiguous (for instance during change from DST to
  non-DST) the total_offset argument is use to try to disambiguise the result.
  If successful the matching result is returned tagged with `:ok`. If the
  `total_offset` argument does not match either, an error will be returned.

  ## Examples:

      iex> from_erl_total_off({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo", -10800, 2)
      {:ok, %Kalends.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: 2} }

      iex> from_erl_total_off({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo", -7200, 2)
      {:ok, %Kalends.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
                    year: 2014, timezone: "America/Montevideo", usec: 2,
                           abbr: "UYST", utc_off: -10800, std_off: 3600}
      }
  """
  def from_erl_total_off(erl_dt, timezone, total_off, usec\\nil) do
    h_from_erl_total_off(from_erl(erl_dt, timezone, usec), total_off)
  end

  defp h_from_erl_total_off({:ok, result}, _total_off), do: {:ok, result}
  defp h_from_erl_total_off({:error, result}, _total_off), do: {:error, result}
  defp h_from_erl_total_off({:ambiguous, result}, total_off) do
    result |> Kalends.AmbiguousDateTime.disamb_total_off(total_off)
  end

  @doc """
  Like `from_erl_total_off/4` but takes a 7 element datetime tuple with
  microseconds instead of a "normal" erlang style tuple.

  ## Examples:

      iex> from_micro_erl_total_off({{2014, 3, 9}, {1, 1, 1, 2}}, "America/Montevideo", -7200)
      {:ok, %Kalends.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
                    year: 2014, timezone: "America/Montevideo", usec: 2,
                           abbr: "UYST", utc_off: -10800, std_off: 3600}
      }
  """
  def from_micro_erl_total_off({{year, mon, day}, {hour, min, sec, usec}}, timezone, total_off) do
    from_erl_total_off({{year, mon, day}, {hour, min, sec}}, timezone, total_off, usec)
  end

  @doc """
  Takes a DateTime struct and returns an erlang style datetime tuple.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC") |> Kalends.DateTime.to_erl
      {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%Kalends.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec}) do
    {{year, month, day}, {hour, min, sec}}
  end

  @doc """
  Takes a DateTime struct and returns an Ecto style datetime tuple. This is
  like an erlang style tuple, but with microseconds added as an additional
  element in the time part of the tuple.

  If the datetime has its usec field set to nil, 0 will be used for usec.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", 999999) |> Kalends.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 999999}}

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", nil) |> Kalends.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 0}}
  """
  def to_micro_erl(%Kalends.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, usec: nil}) do
    {{year, month, day}, {hour, min, sec, 0}}
  end
  def to_micro_erl(%Kalends.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, usec: usec}) do
    {{year, month, day}, {hour, min, sec, usec}}
  end

  @doc """
  Takes a DateTime struct and returns a Date struct representing the date part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Kalends.DateTime.to_date
      %Kalends.Date{day: 15, month: 10, year: 2014}
  """
  def to_date(dt) do
    %Kalends.Date{year: dt.year, month: dt.month, day: dt.day}
  end

  @doc """
  Takes a DateTime struct and returns a Time struct representing the time part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Kalends.DateTime.to_time
      %Kalends.Time{usec: nil, hour: 2, min: 37, sec: 22}
  """
  def to_time(dt) do
    %Kalends.Time{hour: dt.hour, min: dt.min, sec: dt.sec, usec: dt.usec}
  end

  @doc """
  Returns a tuple with a Date struct and a Time struct.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Kalends.DateTime.to_date_and_time
      {%Kalends.Date{day: 15, month: 10, year: 2014}, %Kalends.Time{usec: nil, hour: 2, min: 37, sec: 22}}
  """
  def to_date_and_time(dt) do
    {to_date(dt), to_time(dt)}
  end

  @doc """
  Takes an NaiveDateTime and a time zone identifier and returns a DateTime

      iex> Kalends.NaiveDateTime.from_erl!({{2014,10,15},{2,37,22}}) |> from_naive "UTC"
      {:ok, %Kalends.DateTime{abbr: "UTC", day: 15, usec: nil, hour: 2, min: 37, month: 10, sec: 22, std_off: 0, timezone: "UTC", utc_off: 0, year: 2014}}
  """
  def from_naive(ndt, timezone) do
    ndt |> Kalends.NaiveDateTime.to_erl
    |> from_erl(timezone)
  end

  @doc """
  Takes a DateTime and returns a NaiveDateTime

      iex> Kalends.DateTime.from_erl!({{2014,10,15},{2,37,22}}, "UTC", 0.55) |> to_naive
      %Kalends.NaiveDateTime{day: 15, usec: 0.55, hour: 2, min: 37, month: 10, sec: 22, year: 2014}
  """
  def to_naive(dt) do
    dt |> to_erl
    |> Kalends.NaiveDateTime.from_erl!(dt.usec)
  end

  @doc """
  Takes a DateTime and returns an integer of gregorian seconds starting with
  year 0. This is done via the Erlang calendar module.

  ## Examples

      iex> from_erl!({{2014,9,26},{17,10,20}}, "UTC") |> gregorian_seconds
      63578970620
  """
  def gregorian_seconds(date_time) do
    :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
  end

  def gregorian_seconds_and_usec(date_time) do
    usec = date_time.usec
    {gregorian_seconds(date_time), usec}
  end

  defp validate_erl_datetime({date, _}) do
    :calendar.valid_date date
  end
end
