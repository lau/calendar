defmodule Calendar.DateTime.TzPeriod do
  alias Calendar.TimeZoneData

  @moduledoc """
  DateTime.TzPeriod is for getting information about timezone periods.
  A timezone period is an invention for Calendar, which is a period where the
  offsets are the same for a given time zone. For instance during summer time
  in London where Daylight Saving Time is in effect. The period would be from
  the beginning of summer time until the fall where DST is no longer in effect.

  The functions in this module lets you get the time instance where a period
  begins and when the next begins, terminating the existing period.
  """

  defp timezone_period(date_time) do
    utc_greg_secs = date_time |> Calendar.DateTime.shift_zone!("Etc/UTC") |> Calendar.DateTime.gregorian_seconds
    period_list = TimeZoneData.periods_for_time(date_time.time_zone, utc_greg_secs, :utc);
    hd period_list
  end

  @doc """
  Takes a DateTime. Returns another DateTime with the beginning of the next
  timezone period. Or {:unlimited, :max} in case there are no planned changes
  to the time zone.

  See also `from`.

  ## Examples

      Iceland does not observe DST and has no plans to do so. The period
      that 2000 January 1st is in goes on "forever" and {:unlimited, :max} is
      returned.

      iex> Calendar.DateTime.from_erl!({{2000,1,1},{0,0,0}},"Atlantic/Reykjavik") |> next_from
      {:unlimited, :max}

      The provided DateTime is in summer of 2000 in New York. The period is in
      DST. The returned DateTime is the first instance of winter time, where
      DST is no longer in place:

      iex> Calendar.DateTime.from_erl!({{2000,6,1},{0,0,0}},"America/New_York") |> next_from
      {:ok,
            %DateTime{zone_abbr: "EST", day: 29, hour: 1, microsecond: {0, 0}, minute: 0, month: 10, second: 0, std_offset: 0,
             time_zone: "America/New_York", utc_offset: -18000, year: 2000}}

      The provided DateTime is in winter 2000. The returned DateTime is the
      first second of DST/summer time.

      iex> Calendar.DateTime.from_erl!({{2000,1,1},{0,0,0}},"Europe/Copenhagen") |> next_from
      {:ok,
            %DateTime{zone_abbr: "CEST", day: 26, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600,
             time_zone: "Europe/Copenhagen", utc_offset: 3600, year: 2000}}
  """
  def next_from(date_time) do
    period = date_time |> timezone_period
    case is_integer(period.until.utc) do
      true -> until = period.until.utc
        |> :calendar.gregorian_seconds_to_datetime
        |> Calendar.DateTime.from_erl!("Etc/UTC")
        |> Calendar.DateTime.shift_zone!(date_time.time_zone)
        {:ok, until}
      false -> {:unlimited, period.until.wall}
    end
  end

  @doc """
  Takes a DateTime. Returns the beginning of the timezone period that timezone
  is in as another DateTime in a tuple tagged with :ok

  In case it is the first timezone period, the beginning will be
  "the beginning of time" so to speak. In that case {:unlimited, :min} will
  be returned.

  See also `timezone_period_until`.

  ## Examples

      iex> Calendar.DateTime.from_erl!({{2000,1,1},{0,0,0}},"Atlantic/Reykjavik") |> from
      {:ok,
            %DateTime{zone_abbr: "GMT", day: 7, hour: 2, microsecond: {0, 0}, minute: 0, month: 4, second: 0, std_offset: 0,
             time_zone: "Atlantic/Reykjavik", utc_offset: 0, year: 1968}}

      iex> Calendar.DateTime.from_erl!({{1800,1,1},{0,0,0}},"Atlantic/Reykjavik") |> from
      {:unlimited, :min}
  """
  def from(date_time) do
    period = date_time |> timezone_period
    case is_integer(period.from.utc) do
      true -> from = period.from.utc |> :calendar.gregorian_seconds_to_datetime
        |> Calendar.DateTime.from_erl!("Etc/UTC")
        |> Calendar.DateTime.shift_zone!(date_time.time_zone)
        {:ok, from}
      false -> {:unlimited, period.from.wall}
    end
  end

  @doc """

  ## Examples

      iex> Calendar.DateTime.from_erl!({{2000,1,1},{0,0,0}},"Europe/Copenhagen") |> prev_from
      {:ok,
            %DateTime{zone_abbr: "CEST", day: 28, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600, time_zone: "Europe/Copenhagen", utc_offset: 3600, year: 1999}}

      iex> Calendar.DateTime.from_erl!({{1800,1,1},{0,0,0}},"Atlantic/Reykjavik") |> prev_from
      {:error, :already_at_first}
  """
  def prev_from(date_time) do
    {tag, val} = from(date_time)
    case tag do
      :unlimited -> {:error, :already_at_first}
      _ ->  val
        |> Calendar.DateTime.shift_zone!("Etc/UTC")
        |> Calendar.DateTime.gregorian_seconds
        |> Kernel.-(1)
        |> :calendar.gregorian_seconds_to_datetime
        |> Calendar.DateTime.from_erl!("Etc/UTC")
        |> Calendar.DateTime.shift_zone!(val.time_zone)
        |> from
    end
  end

  @doc """
  Takes a DateTime and returns a stream of next timezone period
  starts. Not including the "from" time of the current timezone period.

  ## Examples

      A DateTime in winter is provided. We take the first 4 elements from the
      stream. The first element is the first instance of the summer time period
      that follows the standard/winter time period the provided DateTime was in.
      The next is standard time. Then Daylight time and Standard time again.

      iex> Calendar.DateTime.from_erl!({{2015,2,24},{13,0,0}}, "America/New_York") |> stream_next_from |> Enum.take(4)
      [%DateTime{zone_abbr: "EDT", day: 8, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600, time_zone: "America/New_York",
             utc_offset: -18000, year: 2015},
            %DateTime{zone_abbr: "EST", day: 1, hour: 1, microsecond: {0, 0}, minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "America/New_York",
             utc_offset: -18000, year: 2015},
            %DateTime{zone_abbr: "EDT", day: 13, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600, time_zone: "America/New_York",
             utc_offset: -18000, year: 2016},
            %DateTime{zone_abbr: "EST", day: 6, hour: 1, microsecond: {0, 0}, minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "America/New_York",
             utc_offset: -18000, year: 2016}]
  """
  def stream_next_from(date_time) do
    Stream.unfold(next_from(date_time), fn {tag, date_time} -> if tag == :ok do {date_time, date_time |> next_from} else nil end end)
  end

  @doc """
  Takes a DateTime and returns a stream of previous "from" timezone period
  starts. Plus the "from" time of the current timezone period.

  ## Examples

      A DateTime in winter is provided. We take the first 4 elements from the
      stream. The first element is the beginning of the period for the DateTime
      provided. The next is the first instance of summer time aka. Eastern
      Daylight Time earlier that year. The next one is standard time before that
      which began in the previous year.

      iex> Calendar.DateTime.from_erl!({{2015,2,24},{13,0,0}}, "America/New_York") |> stream_prev_from |> Enum.take(4)
      [%DateTime{zone_abbr: "EST", day: 2, hour: 1, microsecond: {0, 0}, minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "America/New_York",
             utc_offset: -18000, year: 2014},
            %DateTime{zone_abbr: "EDT", day: 9, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600, time_zone: "America/New_York",
             utc_offset: -18000, year: 2014},
            %DateTime{zone_abbr: "EST", day: 3, hour: 1, microsecond: {0, 0}, minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "America/New_York",
             utc_offset: -18000, year: 2013},
            %DateTime{zone_abbr: "EDT", day: 10, hour: 3, microsecond: {0, 0}, minute: 0, month: 3, second: 0, std_offset: 3600, time_zone: "America/New_York",
             utc_offset: -18000, year: 2013}]
  """
  def stream_prev_from(date_time) do
    Stream.unfold(from(date_time), fn {tag, date_time} -> if tag == :ok do {date_time, date_time |> prev_from} else nil end end)
  end
end
