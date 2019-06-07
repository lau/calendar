defprotocol Calendar.ContainsDateTime do
  @doc """
  Returns a Calendar.DateTime struct for the provided data
  """
  def dt_struct(data)
end

defmodule Calendar.DateTime do
  @moduledoc """
  DateTime provides a struct which represents a certain time and date in a
  certain time zone.

  The functions in this module can be used to create and transform
  DateTime structs.
  """
  alias Tzdata, as: TimeZoneData
  require Calendar.Date
  require Calendar.Time

  @doc """
  Like DateTime.now!("Etc/UTC")
  """
  def now_utc do
    DateTime.utc_now
  end

  @doc """
  Takes a timezone name and returns a DateTime with the current time in
  that timezone. Timezone names must be in the TZ data format.

  Raises in case of an incorrect time zone name.

  ## Examples

      iex > Calendar.DateTime.now! "UTC"
      %DateTime{zone_abbr: "UTC", day: 15, hour: 2,
       minute: 39, month: 10, second: 53, std_offset: 0, time_zone: "UTC", utc_offset: 0,
       year: 2014}

      iex > Calendar.DateTime.now! "Europe/Copenhagen"
      %DateTime{zone_abbr: "CEST", day: 15, hour: 4,
       minute: 41, month: 10, second: 1, std_offset: 3600, time_zone: "Europe/Copenhagen",
       utc_offset: 3600, year: 2014}
  """
  def now!("Etc/UTC"), do: now_utc()
  def now!(timezone) do
    {:ok, datetime} = now(timezone)
    datetime
  end

  @doc """
  Takes a timezone name and returns a DateTime with the current time in
  that timezone. The result is returned in a tuple tagged with :ok

      iex > Calendar.DateTime.now! "Europe/Copenhagen"
      {:ok, %DateTime{zone_abbr: "CEST", day: 15, hour: 4,
       minute: 41, month: 10, second: 1, std_offset: 3600, time_zone: "Europe/Copenhagen",
       utc_offset: 3600, year: 2014}}

      iex> Calendar.DateTime.now "Invalid/Narnia"
      :error
  """
  @spec now(String.t) :: {:ok, DateTime.t} | :error
  def now(timezone) do
    try do
      {now_utc_secs, microsecond} = now_utc() |> gregorian_seconds_and_microsecond
      period_list = TimeZoneData.periods_for_time(timezone, now_utc_secs, :utc)
      period = hd period_list
      {:ok, now_utc_secs + period.utc_off + period.std_off
      |>from_gregorian_seconds!(timezone, period.zone_abbr, period.utc_off, period.std_off, microsecond) }
    rescue
      _ -> :error
    end
  end

  @doc """
  Like shift_zone without "!", but does not check that the time zone is valid
  and just returns a DateTime struct instead of a tuple with a tag.

  ## Example

      iex> from_erl!({{2014,10,2},{0,29,10}},"America/New_York") |> shift_zone!("Europe/Copenhagen")
      %DateTime{zone_abbr: "CEST", day: 2, hour: 6, minute: 29, month: 10, second: 10,
                        time_zone: "Europe/Copenhagen", utc_offset: 3600, std_offset: 3600, year: 2014}

  """
  def shift_zone!(%DateTime{time_zone: timezone} = date_time, timezone), do: date_time # when shifting to same zone, just return the same datetime unchanged
  # In case we are shifting a leap second, shift the second before and then
  # correct the second back to 60. This is to avoid problems with the erlang
  # gregorian second system (lack of) handling of leap seconds.
  def shift_zone!(%DateTime{second: 60} = date_time, timezone) do
    second_before = %DateTime{date_time | second: 59}
    |> shift_zone!(timezone)
    %DateTime{second_before | second: 60}
  end
  def shift_zone!(date_time, timezone) do
    date_time
    |> contained_date_time
    |> shift_to_utc
    |> shift_from_utc(timezone)
  end

  @doc """
  Takes a `DateTime` struct and an integer. Returns a `DateTime` struct in the future which is greater
  by the number of seconds found in the `seconds` argument. *NOTE:* `add/2` ignores leap seconds. The
  calculation is based on the (wrong) assumption that there are no leap seconds.

  ## Examples

      # Add 2 seconds
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York", 123456) |> add(2)
      {:ok, %DateTime{zone_abbr: "EDT", day: 2, hour: 0, minute: 29, month: 10,
            second: 12, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6},
            utc_offset: -18000, year: 2014}}


      # Add 86400 seconds (one day)
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York", 123456) |> add(86400)
      {:ok, %DateTime{zone_abbr: "EDT", day: 3, hour: 0, minute: 29, month: 10,
            second: 10, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6},
            utc_offset: -18000, year: 2014}}

      # Add 10 seconds just before DST "spring forward" so we go from 1:59:59 to 3:00:09
      iex> from_erl!({{2015,3,8},{1,59,59}}, "America/New_York", 123456) |> add(10)
      {:ok, %DateTime{zone_abbr: "EDT", day: 8, hour: 3, minute: 0, month: 3,
            second: 9, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6},
            utc_offset: -18000, year: 2015}}

      # If you add a negative number of seconds, the resulting datetime will effectively
      # be subtracted.
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", 123456) |> add(-200)
      {:ok, %DateTime{zone_abbr: "EDT", day: 1, hour: 23, minute: 56, month: 10, second: 40, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000, year: 2014}}
  """
  def add(dt, seconds), do: advance(dt, seconds)

  @doc """
  Takes a DateTime and an integer. Returns the `date_time` advanced by the number
  of seconds found in the `seconds` argument.

  If `seconds` is negative, the time is moved back.

  NOTE: this ignores leap seconds. The calculation is based on the (wrong) assumption that
  there are no leap seconds.

  ## Examples

      # Add 2 seconds
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York", {123456, 6}) |> add!(2)
      %DateTime{zone_abbr: "EDT", day: 2, hour: 0, minute: 29, month: 10, second: 12,
      std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000,
      year: 2014}

      # Add 86400 seconds (one day)
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York", {123456, 6}) |> add!(86400)
      %DateTime{zone_abbr: "EDT", day: 3, hour: 0, minute: 29, month: 10, second: 10,
      std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000,
      year: 2014}

      # Add 10 seconds just before DST "spring forward" so we go from 1:59:59 to 3:00:09
      iex> from_erl!({{2015,3,8},{1,59,59}}, "America/New_York", {123456, 6}) |> add!(10)
      %DateTime{zone_abbr: "EDT", day: 8, hour: 3, minute: 0, month: 3, second: 9,
      std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000,
      year: 2015}

      # When add a negative integer, the seconds will effectively be subtracted and
      # the result will be a datetime earlier than the the first argument
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", {123456, 6}) |> add!(-200)
      %DateTime{zone_abbr: "EDT", day: 1, hour: 23, minute: 56, month: 10, second: 40, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000, year: 2014}
  """
  def add!(dt, seconds), do: advance!(dt, seconds)


  @doc """
  Takes a `DateTime` struct and an integer. Subtracts the number of seconds found in the
  `seconds` argument.
  *NOTE:* `subtract/2` ignores leap seconds. The
  calculation is based on the (wrong) assumption that there are no leap seconds.

  See `TimeZoneData.leap_seconds/0` function for a list of past leap seconds.

  ## Examples

      # Go back 62 seconds
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", 123456) |> subtract(62)
      {:ok, %DateTime{zone_abbr: "EDT", day: 1, hour: 23, minute: 58, month: 10,
            second: 58, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000,
            year: 2014}}

      # Go back too far so that year would be before 0
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", 123456) |> subtract(999999999999)
      {:error, :function_clause_error}

      # Using a negative amount of seconds with the subtract/2 means effectively adding the absolute amount of seconds
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", 123456) |> subtract!(-200)
      %DateTime{zone_abbr: "EDT", day: 2, hour: 0, minute: 3, month: 10, second: 20, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000, year: 2014}
  """
  def subtract(dt, seconds), do: advance(dt, -1 * seconds)


  @doc """
  Takes a `DateTime` struct and an integer. Returns a `DateTime` struct in the past which is less
  by the number of seconds found in the `seconds` argument. *NOTE:* `subtract!/2` ignores leap seconds. The
  calculation is based on the (wrong) assumption that there are no leap seconds.

  See `Calendar.TimeZoneData.leap_seconds/0` function for a list of past leap seconds.

  ## Examples

      # Go back 62 seconds
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", {123456, 6}) |> subtract!(62)
      %DateTime{zone_abbr: "EDT", day: 1, hour: 23, minute: 58, month: 10, second: 58,
      std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000,
      year: 2014}

      # Go back too far so that year would be before 0
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", {123456, 6}) |> subtract!(999999999999)
      ** (MatchError) no match of right hand side value: {:error, :function_clause_error}

      # Using a negative amount of seconds with the subtract/2 means effectively adding the absolute amount of seconds
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York", {123456, 6}) |> subtract!(-200)
      %DateTime{zone_abbr: "EDT", day: 2, hour: 0, minute: 3, month: 10, second: 20, std_offset: 3600, time_zone: "America/New_York", microsecond: {123456, 6}, utc_offset: -18000, year: 2014}
  """
  def subtract!(dt, seconds) , do: advance!(dt, -1 * seconds)

  @doc """
  Deprecated version of `add/2`
  """
  def advance(date_time, seconds) do
    date_time = date_time |> contained_date_time
    try do
      advanced = date_time
      |> shift_zone!("Etc/UTC")
      |> gregorian_seconds
      |> Kernel.+(seconds)
      |> from_gregorian_seconds!("Etc/UTC", "UTC", 0, 0, date_time.microsecond)
      |> shift_zone!(date_time.time_zone)
      {:ok, advanced}
    rescue
      FunctionClauseError ->
      {:error, :function_clause_error}
    end
  end

  @doc """
  Deprecated version of `add!/2`
  """
  def advance!(date_time, seconds) do
    {:ok, result} = advance(date_time, seconds)
    result
  end

  @doc """
  The difference between two DateTime structs. In seconds and microseconds.

  Leap seconds are ignored.

  Returns tuple with {:ok, seconds, microseconds, :before or :after or :same_time}

  If the first argument is later (e.g. greater) the second, the result will be positive.

  In case of a negative result the second element (seconds) will be negative. This is always
  the case if both of the arguments have the microseconds as 0. But if the difference
  is less than a second and the result is negative, then the microseconds will be negative.

  ## Examples

      # March 30th 2014 02:00:00 in Central Europe the time changed from
      # winter time to summer time. This means that clocks were set forward
      # and an hour skipped. So between 01:00 and 4:00 there were 2 hours
      # not 3. Two hours is 7200 seconds.
      iex> diff(from_erl!({{2014,3,30},{4,0,0}}, "Europe/Stockholm"), from_erl!({{2014,3,30},{1,0,0}}, "Europe/Stockholm"))
      {:ok, 7200, 0, :after}

      # The first DateTime is 40 seconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,50}}, "Etc/UTC"), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC"))
      {:ok, 40, 0, :after}

      # The first DateTime is 40 seconds before the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC"), from_erl!({{2014,10,2},{0,29,50}}, "Etc/UTC"))
      {:ok, -40, 0, :before}

      # The first DateTime is 30 microseconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {31, 5}), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {1, 6}))
      {:ok, 0, 30, :after}

      # The first DateTime is 2 microseconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {0, 0}), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {2, 6}))
      {:ok, 0, -2, :before}

      # The first DateTime is 9.999998 seconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", {0, 0}), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {2,6}))
      {:ok, 9, 999998, :after}

      # The first DateTime is 9.999998 seconds before the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {2, 6}), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", {0, 0}))
      {:ok, -9, 999998, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {0, 0}), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", {2, 6}))
      {:ok, -10, 2, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,1}}, "Etc/UTC", {100, 6}), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {200, 5}))
      {:ok, 0, 999900, :after}

      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {10, 5}), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", {999999, 6}))
      {:ok, 0, -999989, :before}

      # 0:29:10.999999 and 0:29:11 should result in -1 microseconds
      iex> diff(from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", {999999, 6}), from_erl!({{2014,10,2},{0,29,11}}, "Etc/UTC"))
      {:ok, 0, -1, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,11}}, "Etc/UTC"), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", {999999, 6}))
      {:ok, 0, 1, :after}
  """
  def diff(%DateTime{microsecond: {0, _}} = first_dt, %DateTime{microsecond: {0, _}} = second_dt) do
    first_utc = first_dt |> shift_to_utc |> gregorian_seconds
    second_utc = second_dt |> shift_to_utc |> gregorian_seconds
    sec_diff = first_utc - second_utc
    {:ok, sec_diff, 0, gt_lt_eq(sec_diff, 0)}
  end
  def diff(%DateTime{microsecond: {first_microsecond, _}} = first_dt, %DateTime{microsecond: {second_microsecond, _}} = second_dt) do
    {:ok, sec, 0, _} = diff(Map.put(first_dt, :microsecond, {0, 0}), Map.put(second_dt, :microsecond, {0, 0}))
    microsecond = first_microsecond - second_microsecond
    diff_sort_out_decimal {:ok, sec, microsecond}
  end
  def diff(first_cdt, second_cdt) do
    diff(contained_date_time(first_cdt), contained_date_time(second_cdt))
  end

  defp gt_lt_eq(0, 0), do: :same_time
  defp gt_lt_eq(sec, _) when sec < 0, do: :before
  defp gt_lt_eq(sec, _) when sec > 0, do: :after
  defp gt_lt_eq(0, microsecond) when microsecond > 0, do: :after
  defp gt_lt_eq(0, microsecond) when microsecond < 0, do: :before
  defp diff_sort_out_decimal({:ok, sec, microsecond}) when sec > 0 and microsecond < 0 do
    sec = sec - 1
    microsecond = 1_000_000 + microsecond
    {:ok, sec, microsecond, gt_lt_eq(sec, microsecond)}
  end
  defp diff_sort_out_decimal({:ok, sec, microsecond}) when sec == -1 and microsecond > 0 do
    sec = sec + 1
    microsecond = microsecond - 1_000_000
    {:ok, sec, microsecond, gt_lt_eq(sec, microsecond)}
  end
  defp diff_sort_out_decimal({:ok, sec, microsecond}) when sec < 0 and microsecond > 0 do
    sec = sec + 1
    microsecond = 1_000_000 - microsecond
    {:ok, sec, microsecond, gt_lt_eq(sec, microsecond)}
  end
  defp diff_sort_out_decimal({:ok, sec, microsecond}) when sec < 0 and microsecond < 0 do
    {:ok, sec, abs(microsecond), gt_lt_eq(sec, microsecond)}
  end
  defp diff_sort_out_decimal({:ok, sec, microsecond}) do
    {:ok, sec, microsecond, gt_lt_eq(sec, microsecond)}
  end

  @doc """
  Takes a two `DateTime`s and returns true if the first
  one is greater than the second. Otherwise false. Greater than
  means that it is later then the second datetime.

  ## Examples

      # The wall times of the two times are the same, but the one in Los Angeles
      # happens after the one in UTC because Los Angeles is behind UTC
      iex> from_erl!({{2014,1,1}, {11,11,11}}, "America/Los_Angeles") |> after?(from_erl!({{2014, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      true
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> after?(from_erl!({{1999, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      true
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> after?(from_erl!({{2020, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      false
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> after?(from_erl!({{2014, 1, 1}, {10, 10, 10}}, "Etc/UTC"))
      false
  """
  def after?(dt1, dt2) do
    {_, _, _, comparison} = diff(dt1, dt2)
    comparison == :after
  end

  @doc """
  Takes a two `DateTime`s and returns true if the first
  one is less than the second. Otherwise false. Less than
  means that it is earlier then the second datetime.

  ## Examples

      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> before?(from_erl!({{1999, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      false
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> before?(from_erl!({{2020, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      true
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> before?(from_erl!({{2014, 1, 1}, {10, 10, 10}}, "Etc/UTC"))
      false
  """
  def before?(dt1, dt2) do
    {_, _, _, comparison} = diff(dt1, dt2)
    comparison == :before
  end
  @doc """
  Takes a two `DateTime`s and returns true if the first
  is at the same time as the second one.

  ## Examples

      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> same_time?(from_erl!({{2014, 1, 1}, {10, 10, 10}}, "Etc/UTC"))
      true
      # 10:00 in London is the same time as 11:00 in Copenhagen
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Europe/London") |> same_time?(from_erl!({{2014, 1, 1}, {11, 10, 10}}, "Europe/Copenhagen"))
      true
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "America/Godthab") |> same_time?(from_erl!({{2014, 1, 1}, {10, 10, 10}}, "Etc/UTC"))
      false
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Etc/UTC") |> same_time?(from_erl!({{2020, 1, 1}, {11, 11, 11}}, "Etc/UTC"))
      false
      iex> from_erl!({{2014,1,1}, {10,10,10}}, "Europe/London") |> same_time?(from_erl!({{2014, 1, 1}, {10, 10, 10}}, "Etc/UTC"))
      true
  """
  def same_time?(dt1, dt2) do
    {_, _, _, comparison} = diff(dt1, dt2)
    comparison == :same_time
  end

  @doc """
  Takes a DateTime and the name of a new timezone.
  Returns a DateTime with the equivalent time in the new timezone.

  ## Examples

      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York",123456) |> shift_zone("Europe/Copenhagen")
      {:ok, %DateTime{zone_abbr: "CEST", day: 2, hour: 6, minute: 29, month: 10, second: 10, time_zone: "Europe/Copenhagen", utc_offset: 3600, std_offset: 3600, year: 2014, microsecond: {123456, 6}}}

      iex> {:ok, nyc} = from_erl {{2014,10,2},{0,29,10}},"America/New_York"; shift_zone(nyc, "Invalid timezone")
      {:invalid_time_zone, nil}
  """

  def shift_zone(date_time, timezone) do
    case TimeZoneData.zone_exists?(timezone) do
      true -> {:ok, shift_zone!(date_time, timezone)}
      false -> {:invalid_time_zone, nil}
    end
  end

  defp shift_to_utc(%DateTime{time_zone: "Etc/UTC"} = dt), do: dt
  defp shift_to_utc(%DateTime{} = date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
    period_list = TimeZoneData.periods_for_time(date_time.time_zone, greg_secs, :wall)
    period = period_by_offset(period_list, date_time.utc_offset, date_time.std_offset)
    greg_secs-period.utc_off-period.std_off
    |>from_gregorian_seconds!("Etc/UTC", "UTC", 0, 0, date_time.microsecond)
  end
  defp shift_to_utc(date_time) do
    date_time |> contained_date_time |> shift_to_utc
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
    |>from_gregorian_seconds!(to_timezone, period.zone_abbr, period.utc_off, period.std_off, utc_date_time.microsecond)
  end

  # Takes gregorian seconds and and optional timezone.
  # Returns a DateTime.

  # ## Examples
  #   iex> from_gregorian_seconds!(63578970620)
  #   %DateTime{date: 26, hour: 17, minute: 10, month: 9, second: 20, time_zone: nil, year: 2014}
  #   iex> from_gregorian_seconds!(63578970620, "America/Montevideo")
  #   %DateTime{date: 26, hour: 17, minute: 10, month: 9, second: 20, time_zone: "America/Montevideo", year: 2014}
  defp from_gregorian_seconds!(gregorian_seconds, timezone, abbr, utc_off, std_off, microsecond) do
    gregorian_seconds
    |>:calendar.gregorian_seconds_to_datetime
    |>from_erl!(timezone, abbr, utc_off, std_off, microsecond)
  end

  @doc """
  Takes an erlang style 3 touple timestamp with the form:
  {megasecs, secs, microsecs}

  This is the form returned by the Erlang function `:erlang.timestamp()`

  ## Examples

      iex> from_erlang_timestamp({1453, 854322, 799236})
      %DateTime{zone_abbr: "UTC", day: 27, hour: 0, minute: 25, month: 1, second: 22, std_offset: 0,
            time_zone: "Etc/UTC", microsecond: {799236, 6}, utc_offset: 0, year: 2016}
  """
  def from_erlang_timestamp({_, _, microsecond} = erlang_timestamp) do
    dt = erlang_timestamp |> :calendar.now_to_universal_time
    from_erl!(dt, "Etc/UTC" , {microsecond, 6})
  end

  @doc """
  Like from_erl/2 without "!", but returns the result directly without a tag.
  Will raise if date is ambiguous or invalid! Only use this if you are sure
  the date is valid. Otherwise use "from_erl" without the "!".

  Example:

      iex> from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
      %DateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20, year: 2014, time_zone: "America/Montevideo", zone_abbr: "-03", utc_offset: -10800, std_offset: 0}
  """
  def from_erl!(date_time, time_zone, microsecond \\ {0, 0}) do
    {:ok, result} = from_erl(date_time, time_zone, microsecond)
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
      {:ok, %DateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20,
                              year: 2014, time_zone: "America/Montevideo",
                              zone_abbr: "-03",
                              utc_offset: -10800, std_offset: 0, microsecond: {0, 0}} }

    Switching from summer to wintertime in the fall means an ambigous time.

      iex> from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo")
      {:ambiguous, %Calendar.AmbiguousDateTime{possible_date_times:
        [%DateTime{day: 9, hour: 1, minute: 1, month: 3, second: 1,
                           year: 2014, time_zone: "America/Montevideo",
                           zone_abbr: "-02", utc_offset: -10800, std_offset: 3600},
         %DateTime{day: 9, hour: 1, minute: 1, month: 3, second: 1,
                           year: 2014, time_zone: "America/Montevideo",
                           zone_abbr: "-03", utc_offset: -10800, std_offset: 0},
        ]}
      }

      iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "Non-existing timezone")
      {:error, :timezone_not_found}

    The time between 2:00 and 3:00 in the following example does not exist
    because of the one hour gap caused by switching to DST.

      iex> from_erl({{2014, 3, 30}, {2, 20, 02}}, "Europe/Copenhagen")
      {:error, :invalid_datetime_for_timezone}

    Time with fractional seconds. This represents the time 17:10:20.987654321

      iex> from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo", {987654, 6})
      {:ok, %DateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20,
                              year: 2014, time_zone: "America/Montevideo",
                              zone_abbr: "-03",
                              utc_offset: -10800, std_offset: 0, microsecond: {987654, 6}} }

  """
  def from_erl(date_time, timezone, microsecond \\ {0, 0})
  def from_erl(date_time, timezone, microsecond) when is_integer(microsecond) do
    from_erl(date_time, timezone, {microsecond, 6})
  end
  def from_erl({date, {h, m, s, microsecond}}, timezone, _ignored_extra_microsecond) do
    date_time = {date, {h, m, s}}
    validity = validate_erl_datetime(date_time, timezone)
    from_erl_validity(date_time, timezone, validity, {microsecond, 6})
  end
  def from_erl(date_time, timezone, microsecond) do
    validity = validate_erl_datetime(date_time, timezone)
    from_erl_validity(date_time, timezone, validity, microsecond)
  end

  # Date, time and timezone. Date and time is valid.
  defp from_erl_validity({{year, month, day}, {hour, minute, second}}, "Etc/UTC", true, microsecond) do
    # "Fast track" version for UTC
    # In case of UTC, we already know the timezone exists and will not query any Tzdata
    {:ok, %DateTime{zone_abbr: "UTC", day: day, hour: hour, minute: minute, month: month, second: second, std_offset: 0, time_zone: "Etc/UTC", microsecond: microsecond, utc_offset: 0, year: year}}
  end
  defp from_erl_validity(datetime, timezone, true, microsecond) do
    # validate that timezone exists
    from_erl_timezone_validity(datetime, timezone, TimeZoneData.zone_exists?(timezone), microsecond)
  end
  defp from_erl_validity(_, _, false, _) do
    {:error, :invalid_datetime}
  end

  defp from_erl_timezone_validity(_, _, false, _), do: {:error, :timezone_not_found}
  defp from_erl_timezone_validity({date, time}, timezone, true, microsecond) do
    # get periods for time
    greg_secs = :calendar.datetime_to_gregorian_seconds({date, time})
    periods = TimeZoneData.periods_for_time(timezone, greg_secs, :wall)
    from_erl_periods({date, time}, timezone, periods, microsecond)
  end

  defp from_erl_periods(_, _, periods, _) when periods == [] do
    {:error, :invalid_datetime_for_timezone}
  end
  defp from_erl_periods({{year, month, day}, {hour, min, sec}}, timezone, periods, microsecond) when length(periods) == 1 do
    period = periods |> hd
    {:ok, %DateTime{year: year, month: month, day: day, hour: hour,
         minute: min, second: sec, time_zone: timezone, zone_abbr: period.zone_abbr,
         utc_offset: period.utc_off, std_offset: period.std_off, microsecond: microsecond } }
  end
  # When a time is ambigous (for instance switching from summer- to winter-time)
  defp from_erl_periods({{year, month, day}, {hour, min, sec}}, timezone, periods, microsecond) when length(periods) == 2 do
    possible_date_times =
    Enum.map(periods, fn period ->
           %DateTime{year: year, month: month, day: day, hour: hour,
           minute: min, second: sec, time_zone: timezone, zone_abbr: period.zone_abbr,
           utc_offset: period.utc_off, std_offset: period.std_off, microsecond: microsecond }
       end )
    # sort by abbreviation
    |> Enum.sort(fn dt1, dt2 -> dt1.zone_abbr <= dt2.zone_abbr end)

    {:ambiguous, %Calendar.AmbiguousDateTime{ possible_date_times: possible_date_times} }
  end

  defp from_erl!({{year, month, day}, {hour, min, sec}}, timezone, abbr, utc_off, std_off, microsecond) do
    %DateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, time_zone: timezone, zone_abbr: abbr, utc_offset: utc_off, std_offset: std_off, microsecond: microsecond}
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
      {:ok, %DateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20,
                              year: 2014, time_zone: "America/Montevideo",
                              zone_abbr: "-03",
                              utc_offset: -10800, std_offset: 0, microsecond: {2, 6}} }

      iex> from_erl_total_off({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo", -7200, 2)
      {:ok, %DateTime{day: 9, hour: 1, minute: 1, month: 3, second: 1,
                    year: 2014, time_zone: "America/Montevideo", microsecond: {2, 6},
                           zone_abbr: "-02", utc_offset: -10800, std_offset: 3600}
      }
  """
  def from_erl_total_off(erl_dt, timezone, total_off, microsecond\\{0,0}) do
    h_from_erl_total_off(from_erl(erl_dt, timezone, microsecond), total_off)
  end

  defp h_from_erl_total_off({:ok, result}, _total_off), do: {:ok, result}
  defp h_from_erl_total_off({:error, result}, _total_off), do: {:error, result}
  defp h_from_erl_total_off({:ambiguous, result}, total_off) do
    result |> Calendar.AmbiguousDateTime.disamb_total_off(total_off)
  end

  @doc """
  Like `from_erl_total_off/4` but takes a 7 element datetime tuple with
  microseconds instead of a "normal" erlang style tuple.

  ## Examples:

      iex> from_micro_erl_total_off({{2014, 3, 9}, {1, 1, 1, 2}}, "America/Montevideo", -7200)
      {:ok, %DateTime{day: 9, hour: 1, minute: 1, month: 3, second: 1,
                    year: 2014, time_zone: "America/Montevideo", microsecond: {2, 6},
                           zone_abbr: "-02", utc_offset: -10800, std_offset: 3600}
      }
  """
  def from_micro_erl_total_off({{year, mon, day}, {hour, min, sec, microsecond}}, timezone, total_off) do
    from_erl_total_off({{year, mon, day}, {hour, min, sec}}, timezone, total_off, microsecond)
  end

  @doc """
  Takes a DateTime struct and returns an erlang style datetime tuple.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC") |> Calendar.DateTime.to_erl
      {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%DateTime{year: year, month: month, day: day, hour: hour, minute: min, second: second}) do
    {{year, month, day}, {hour, min, second}}
  end
  def to_erl(date_time) do
    date_time |> contained_date_time |> to_erl
  end

  @doc """
  Takes a DateTime struct and returns an Ecto style datetime tuple. This is
  like an erlang style tuple, but with microseconds added as an additional
  element in the time part of the tuple.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", {999999, 6}) |> Calendar.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 999999}}

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", {0, 0}) |> Calendar.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 0}}
  """
  def to_micro_erl(%DateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, microsecond: {0, 0}}) do
    {{year, month, day}, {hour, min, sec, 0}}
  end
  def to_micro_erl(%DateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, microsecond: {microsecond,_}}) do
    {{year, month, day}, {hour, min, sec, microsecond}}
  end
  def to_micro_erl(date_time) do
    date_time |> contained_date_time |> to_micro_erl
  end

  @doc """
  Takes a DateTime struct and returns a Date struct representing the date part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_date
      %Date{day: 15, month: 10, year: 2014}
  """
  def to_date(%DateTime{} = dt) do
    %Date{year: dt.year, month: dt.month, day: dt.day}
  end
  def to_date(dt), do: dt |> contained_date_time |> to_date

  @doc """
  Takes a DateTime struct and returns a Time struct representing the time part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_time
      %Time{microsecond: {0, 0}, hour: 2, minute: 37, second: 22}
  """
  def to_time(%DateTime{} = dt) do
    %Time{hour: dt.hour, minute: dt.minute, second: dt.second, microsecond: dt.microsecond}
  end
  def to_time(dt), do: dt |> contained_date_time |> to_time

  @doc """
  Returns a tuple with a Date struct and a Time struct.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_date_and_time
      {%Date{day: 15, month: 10, year: 2014}, %Time{microsecond: {0, 0}, hour: 2, minute: 37, second: 22}}
  """
  def to_date_and_time(%DateTime{} = dt) do
    {to_date(dt), to_time(dt)}
  end
  def to_date_and_time(dt), do: dt |> contained_date_time |> to_date_and_time

  @doc """
  Takes an NaiveDateTime and a time zone identifier and returns a DateTime

      iex> Calendar.NaiveDateTime.from_erl!({{2014,10,15},{2,37,22}}) |> from_naive("Etc/UTC")
      {:ok, %DateTime{zone_abbr: "UTC", day: 15, microsecond: {0, 0}, hour: 2, minute: 37, month: 10, second: 22, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2014}}

      iex> Calendar.NaiveDateTime.from_erl!({{2014,10,15},{2,37,22}}, {13, 6}) |> from_naive("Etc/UTC")
      {:ok, %DateTime{zone_abbr: "UTC", day: 15, microsecond: {13, 6}, hour: 2, minute: 37, month: 10, second: 22, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2014}}

  """
  def from_naive(ndt, timezone) do
    ndt
    |> Calendar.NaiveDateTime.to_erl
    |> from_erl(timezone, ndt.microsecond)
  end

  @doc """
  Takes a DateTime and returns a NaiveDateTime

      iex> Calendar.DateTime.from_erl!({{2014,10,15},{2,37,22}}, "UTC", 55) |> to_naive
      %NaiveDateTime{day: 15, microsecond: {55, 6}, hour: 2, minute: 37, month: 10, second: 22, year: 2014}
  """
  def to_naive(dt) do
    dt |> to_erl
    |> Calendar.NaiveDateTime.from_erl!(dt.microsecond)
  end

  @doc """
  Takes a DateTime and returns an integer of gregorian seconds starting with
  year 0. This is done via the Erlang calendar module.

  ## Examples

      iex> from_erl!({{2014,9,26},{17,10,20}}, "UTC") |> gregorian_seconds
      63578970620
  """
  def gregorian_seconds(date_time) do
    date_time = date_time |> contained_date_time
    :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
  end

  def gregorian_seconds_and_microsecond(date_time) do
    date_time = date_time |> contained_date_time
    microsecond = date_time.microsecond
    {gregorian_seconds(date_time), microsecond}
  end

  @doc """
  Create new DateTime struct based on a date and a time and a timezone string.

  ## Examples

      iex> from_date_and_time_and_zone({2016, 1, 8}, {14, 10, 55}, "Etc/UTC")
      {:ok, %DateTime{day: 8, microsecond: {0, 0}, hour: 14, minute: 10, month: 1, second: 55, year: 2016, zone_abbr: "UTC", time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}}
  """
  def from_date_and_time_and_zone(date_container, time_container, timezone) do
    contained_time = Calendar.ContainsTime.time_struct(time_container)
    from_erl({Calendar.Date.to_erl(date_container), Calendar.Time.to_erl(contained_time)}, timezone, contained_time.microsecond)
  end

  @doc """
  Like `from_date_and_time_and_zone`, but returns result untagged and
  raises in case of an error or ambiguous datetime.

  ## Examples

      iex> from_date_and_time_and_zone!({2016, 1, 8}, {14, 10, 55}, "Etc/UTC")
      %DateTime{day: 8, microsecond: {0, 0}, hour: 14, minute: 10, month: 1, second: 55, year: 2016, zone_abbr: "UTC", time_zone: "Etc/UTC", utc_offset: 0, std_offset: 0}
  """
  def from_date_and_time_and_zone!(date_container, time_container, timezone) do
    {:ok, result} = from_date_and_time_and_zone(date_container, time_container, timezone)
    result
  end

  defp contained_date_time(dt_container) do
    Calendar.ContainsDateTime.dt_struct(dt_container)
  end

  defp validate_erl_datetime({date, time}, timezone) do
    :calendar.valid_date(date) && valid_time_part_of_datetime(date, time, timezone)
  end
  # Validate time part of a datetime
  # The date and timezone part is only used for leap seconds
  defp valid_time_part_of_datetime(date, {h, m, 60}, "Etc/UTC") do
    TimeZoneData.leap_seconds |> Enum.member?({date, {h, m, 60}})
  end
  defp valid_time_part_of_datetime(date, {h, m, 60}, timezone) do
    {tag, utc_datetime} = from_erl({date, {h, m, 59}}, timezone)
    case tag do
      :ok -> {date_utc, {h, m, s}} = utc_datetime
        |> shift_zone!("Etc/UTC")
        |> to_erl
        valid_time_part_of_datetime(date_utc, {h, m, s+1}, "Etc/UTC")
      _ -> false
    end
  end
  defp valid_time_part_of_datetime(_date, {h, m, s}, _timezone) do
    h>=0 and h<=23 and m>=0 and m<=59 and s>=0 and s<=60
  end
end

defimpl Calendar.ContainsDateTime, for: DateTime do
  def dt_struct(data), do: data
end
defimpl Calendar.ContainsDateTime, for: Calendar.DateTime do
  def dt_struct(%{calendar: Calendar.ISO}=data), do: %DateTime{day: data.day, month: data.month, year: data.year, hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond, zone_abbr: data.zone_abbr, time_zone: data.time_zone, utc_offset: data.utc_offset, std_offset: data.std_offset}
end
