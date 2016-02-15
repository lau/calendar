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
  alias Calendar.TimeZoneData
  alias Calendar.ContainsDateTime
  require Calendar.Date
  require Calendar.Time

  defstruct [:year, :month, :day, :hour, :min, :sec, :usec, :timezone, :abbr, :utc_off, :std_off]

  @doc """
  Like DateTime.now!("Etc/UTC")
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

      iex > DateTime.now! "UTC"
      %Calendar.DateTime{abbr: "UTC", day: 15, hour: 2,
       min: 39, month: 10, sec: 53, std_off: 0, timezone: "UTC", utc_off: 0,
       year: 2014}

      iex > DateTime.now! "Europe/Copenhagen"
      %Calendar.DateTime{abbr: "CEST", day: 15, hour: 4,
       min: 41, month: 10, sec: 1, std_off: 3600, timezone: "Europe/Copenhagen",
       utc_off: 3600, year: 2014}
  """
  def now!("Etc/UTC"), do: now_utc
  def now!(timezone) do
    {now_utc_secs, usec} = now_utc |> gregorian_seconds_and_usec
    period_list = TimeZoneData.periods_for_time(timezone, now_utc_secs, :utc)
    period = hd period_list
    now_utc_secs + period.utc_off + period.std_off
    |>from_gregorian_seconds!(timezone, period.zone_abbr, period.utc_off, period.std_off, usec)
  end

  @doc """
  Deprecated version of `now!/1` with an exclamation point.
  Works the same way as `now!/1`.

  In the future `now/1` will return a tuple with {:ok, [DateTime]}
  """
  def now(timezone) do
    IO.puts :stderr, "Warning: now/1 is deprecated. Use now!/1 instead (with a !) " <>
                     "In the future now/1 will return a tuple with {:ok, [DateTime]}\n" <> Exception.format_stacktrace()
    now!(timezone)
  end

  @doc """
  Like shift_zone without "!", but does not check that the time zone is valid
  and just returns a DateTime struct instead of a tuple with a tag.

  ## Example

      iex> from_erl!({{2014,10,2},{0,29,10}},"America/New_York") |> shift_zone!("Europe/Copenhagen")
      %Calendar.DateTime{abbr: "CEST", day: 2, hour: 6, min: 29, month: 10, sec: 10,
                        timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 2014}

  """
  def shift_zone!(%Calendar.DateTime{timezone: timezone} = date_time, timezone), do: date_time # when shifting to same zone, just return the same datetime unchanged
  # In case we are shifting a leap second, shift the second before and then
  # correct the second back to 60. This is to avoid problems with the erlang
  # gregorian second system (lack of) handling of leap seconds.
  def shift_zone!(%Calendar.DateTime{sec: 60} = date_time, timezone) do
    second_before = %Calendar.DateTime{date_time | sec: 59}
    |> shift_zone!(timezone)
    %Calendar.DateTime{second_before | sec: 60}
  end
  def shift_zone!(date_time, timezone) do
    date_time
    |> contained_date_time
    |>shift_to_utc
    |>shift_from_utc(timezone)
  end

  @doc """
  Takes a DateTime and an integer. Returns the `date_time` advanced by the number
  of seconds found in the `seconds` argument.

  If `seconds` is negative, the time is moved back.

  The advancement is done in UTC. The datetime is converted to UTC, then
  advanced, then converted back.

  NOTE: this ignores leap seconds. The calculation is based on the (wrong) assumption that
  there are no leap seconds.

  ## Examples

      # Advance 2 seconds
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York",123456) |> advance(2)
      {:ok, %Calendar.DateTime{abbr: "EDT", day: 2, hour: 0, min: 29, month: 10,
            sec: 12, std_off: 3600, timezone: "America/New_York", usec: 123456,
            utc_off: -18000, year: 2014}}

      # Advance 86400 seconds (one day)
      iex> from_erl!({{2014,10,2},{0,29,10}}, "America/New_York",123456) |> advance(86400)
      {:ok, %Calendar.DateTime{abbr: "EDT", day: 3, hour: 0, min: 29, month: 10,
            sec: 10, std_off: 3600, timezone: "America/New_York", usec: 123456,
            utc_off: -18000, year: 2014}}

      # Go back 62 seconds
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York",123456) |> advance(-62)
      {:ok, %Calendar.DateTime{abbr: "EDT", day: 1, hour: 23, min: 58, month: 10,
            sec: 58, std_off: 3600, timezone: "America/New_York", usec: 123456, utc_off: -18000,
            year: 2014}}

      # Advance 10 seconds just before DST "spring forward" so we go from 1:59:59 to 3:00:09
      iex> from_erl!({{2015,3,8},{1,59,59}}, "America/New_York",123456) |> advance(10)
      {:ok, %Calendar.DateTime{abbr: "EDT", day: 8, hour: 3, min: 0, month: 3,
            sec: 9, std_off: 3600, timezone: "America/New_York", usec: 123456,
            utc_off: -18000, year: 2015}}

      # Go back too far so that year would be before 0
      iex> from_erl!({{2014,10,2},{0,0,0}}, "America/New_York",123456) |> advance(-999999999999)
      {:error, :function_clause_error}
  """
  def advance(date_time, seconds) do
    date_time = date_time |> contained_date_time
    try do
      advanced = date_time
      |> shift_zone!("Etc/UTC")
      |> gregorian_seconds
      |> + seconds
      |> from_gregorian_seconds!("Etc/UTC", "UTC", 0, 0, date_time.usec)
      |> shift_zone!(date_time.timezone)
      {:ok, advanced}
    rescue
      FunctionClauseError ->
      {:error, :function_clause_error}
    end
  end

  @doc """
  Like `advance` without exclamation points.
  Instead of returning a tuple with :ok and the result,
  the result is returned untagged. Will raise an error in case
  no correct result can be found based on the arguments.
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
  the case if both of the arguments have the microseconds as nil or 0. But if the difference
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
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 31), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 1))
      {:ok, 0, 30, :after}

      # The first DateTime is 2 microseconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 0), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 2))
      {:ok, 0, -2, :before}

      # The first DateTime is 9.999998 seconds after the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", 0), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 2))
      {:ok, 9, 999998, :after}

      # The first DateTime is 9.999998 seconds before the second DateTime
      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 2), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", 0))
      {:ok, -9, 999998, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 0), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", 2))
      {:ok, -10, 2, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,1}}, "Etc/UTC", 100), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 200))
      {:ok, 0, 999900, :after}

      iex> diff(from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 10), from_erl!({{2014,10,2},{0,29,0}}, "Etc/UTC", 999999))
      {:ok, 0, -999989, :before}

      # 0:29:10.999999 and 0:29:11 should result in -1 microseconds
      iex> diff(from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", 999999), from_erl!({{2014,10,2},{0,29,11}}, "Etc/UTC"))
      {:ok, 0, -1, :before}

      iex> diff(from_erl!({{2014,10,2},{0,29,11}}, "Etc/UTC"), from_erl!({{2014,10,2},{0,29,10}}, "Etc/UTC", 999999))
      {:ok, 0, 1, :after}
  """
  # If any datetime usec is nil, set it to 0
  def diff(%Calendar.DateTime{usec: nil} = first_dt, %Calendar.DateTime{usec: nil} = second_dt) do
    diff(Map.put(first_dt, :usec, 0), Map.put(second_dt, :usec, 0))
  end
  def diff(%Calendar.DateTime{usec: nil} = first_dt, %Calendar.DateTime{} = second_dt) do
    diff(Map.put(first_dt, :usec, 0), second_dt)
  end
  def diff(%Calendar.DateTime{} = first_dt, %Calendar.DateTime{usec: nil} = second_dt) do
    diff(first_dt, Map.put(second_dt, :usec, 0))
  end

  def diff(%Calendar.DateTime{usec: 0} = first_dt, %Calendar.DateTime{usec: 0} = second_dt) do
    first_utc = first_dt |> shift_to_utc |> gregorian_seconds
    second_utc = second_dt |> shift_to_utc |> gregorian_seconds
    sec_diff = first_utc - second_utc
    {:ok, sec_diff, 0, gt_lt_eq(sec_diff, 0)}
  end
  def diff(%Calendar.DateTime{usec: first_usec} = first_dt, %Calendar.DateTime{usec: second_usec} = second_dt) do
    {:ok, sec, 0, _} = diff(Map.put(first_dt, :usec, 0), Map.put(second_dt, :usec, 0))
    usec = first_usec - second_usec
    diff_sort_out_decimal {:ok, sec, usec}
  end
  def diff(first_cdt, second_cdt) do
    diff(contained_date_time(first_cdt), contained_date_time(second_cdt))
  end

  defp gt_lt_eq(0, 0), do: :same_time
  defp gt_lt_eq(sec, _) when sec < 0, do: :before
  defp gt_lt_eq(sec, _) when sec > 0, do: :after
  defp gt_lt_eq(0, usec) when usec > 0, do: :after
  defp gt_lt_eq(0, usec) when usec < 0, do: :before
  defp diff_sort_out_decimal({:ok, sec, usec}) when sec > 0 and usec < 0 do
    sec = sec - 1
    usec = 1_000_000 + usec
    {:ok, sec, usec, gt_lt_eq(sec, usec)}
  end
  defp diff_sort_out_decimal({:ok, sec, usec}) when sec == -1 and usec > 0 do
    sec = sec + 1
    usec = usec - 1_000_000
    {:ok, sec, usec, gt_lt_eq(sec, usec)}
  end
  defp diff_sort_out_decimal({:ok, sec, usec}) when sec < 0 and usec > 0 do
    sec = sec + 1
    usec = 1_000_000 - usec
    {:ok, sec, usec, gt_lt_eq(sec, usec)}
  end
  defp diff_sort_out_decimal({:ok, sec, usec}) when sec < 0 and usec < 0 do
    {:ok, sec, abs(usec), gt_lt_eq(sec, usec)}
  end
  defp diff_sort_out_decimal({:ok, sec, usec}) do
    {:ok, sec, usec, gt_lt_eq(sec, usec)}
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
      {:ok, %Calendar.DateTime{abbr: "CEST", day: 2, hour: 6, min: 29, month: 10, sec: 10, timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 2014, usec: 123456}}

      iex> {:ok, nyc} = from_erl {{2014,10,2},{0,29,10}},"America/New_York"; shift_zone(nyc, "Invalid timezone")
      {:invalid_time_zone, nil}
  """

  def shift_zone(date_time, timezone) do
    case TimeZoneData.zone_exists?(timezone) do
      true -> {:ok, shift_zone!(date_time, timezone)}
      false -> {:invalid_time_zone, nil}
    end
  end

  defp shift_to_utc(%Calendar.DateTime{timezone: "Etc/UTC"} = dt), do: dt
  defp shift_to_utc(%Calendar.DateTime{} = date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(date_time|>to_erl)
    period_list = TimeZoneData.periods_for_time(date_time.timezone, greg_secs, :wall)
    period = period_by_offset(period_list, date_time.utc_off, date_time.std_off)
    greg_secs-period.utc_off-period.std_off
    |>from_gregorian_seconds!("Etc/UTC", "UTC", 0, 0, date_time.usec)
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
    |>from_gregorian_seconds!(to_timezone, period.zone_abbr, period.utc_off, period.std_off, utc_date_time.usec)
  end

  # Takes gregorian seconds and and optional timezone.
  # Returns a DateTime.

  # ## Examples
  #   iex> from_gregorian_seconds!(63578970620)
  #   %Calendar.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: nil, year: 2014}
  #   iex> from_gregorian_seconds!(63578970620, "America/Montevideo")
  #   %Calendar.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, timezone: "America/Montevideo", year: 2014}
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
      %Calendar.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014, timezone: "America/Montevideo", abbr: "UYT", utc_off: -10800, std_off: 0}
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
      {:ok, %Calendar.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: nil} }

    Switching from summer to wintertime in the fall means an ambigous time.

      iex> from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo")
      {:ambiguous, %Calendar.AmbiguousDateTime{possible_date_times:
        [%Calendar.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
                           year: 2014, timezone: "America/Montevideo",
                           abbr: "UYST", utc_off: -10800, std_off: 3600},
         %Calendar.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
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
      {:ok, %Calendar.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: 987654} }

  """
  def from_erl(date_time, timezone, usec \\ nil)
  def from_erl({date, {h, m, s, usec}}, timezone, _ignored_extra_usec) do
    date_time = {date, {h, m, s}}
    validity = validate_erl_datetime(date_time, timezone)
    from_erl_validity(date_time, timezone, validity, usec)
  end
  def from_erl(date_time, timezone, usec) do
    validity = validate_erl_datetime(date_time, timezone)
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
    {:ok, %Calendar.DateTime{year: year, month: month, day: day, hour: hour,
         min: min, sec: sec, timezone: timezone, abbr: period.zone_abbr,
         utc_off: period.utc_off, std_off: period.std_off, usec: usec } }
  end
  # When a time is ambigous (for instance switching from summer- to winter-time)
  defp from_erl_periods({{year, month, day}, {hour, min, sec}}, timezone, periods, usec) when length(periods) == 2 do
    possible_date_times =
    Enum.map(periods, fn period ->
           %Calendar.DateTime{year: year, month: month, day: day, hour: hour,
           min: min, sec: sec, timezone: timezone, abbr: period.zone_abbr,
           utc_off: period.utc_off, std_off: period.std_off, usec: usec }
       end )
    # sort by abbreviation
    |> Enum.sort(fn dt1, dt2 -> dt1.abbr <= dt2.abbr end)

    {:ambiguous, %Calendar.AmbiguousDateTime{ possible_date_times: possible_date_times} }
  end

  defp from_erl!({{year, month, day}, {hour, min, sec}}, timezone, abbr, utc_off, std_off, usec) do
    %Calendar.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, timezone: timezone, abbr: abbr, utc_off: utc_off, std_off: std_off, usec: usec}
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
      {:ok, %Calendar.DateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20,
                              year: 2014, timezone: "America/Montevideo",
                              abbr: "UYT",
                              utc_off: -10800, std_off: 0, usec: 2} }

      iex> from_erl_total_off({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo", -7200, 2)
      {:ok, %Calendar.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
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
    result |> Calendar.AmbiguousDateTime.disamb_total_off(total_off)
  end

  @doc """
  Like `from_erl_total_off/4` but takes a 7 element datetime tuple with
  microseconds instead of a "normal" erlang style tuple.

  ## Examples:

      iex> from_micro_erl_total_off({{2014, 3, 9}, {1, 1, 1, 2}}, "America/Montevideo", -7200)
      {:ok, %Calendar.DateTime{day: 9, hour: 1, min: 1, month: 3, sec: 1,
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

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC") |> Calendar.DateTime.to_erl
      {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%Calendar.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec}) do
    {{year, month, day}, {hour, min, sec}}
  end
  def to_erl(date_time) do
    date_time |> contained_date_time |> to_erl
  end

  @doc """
  Takes a DateTime struct and returns an Ecto style datetime tuple. This is
  like an erlang style tuple, but with microseconds added as an additional
  element in the time part of the tuple.

  If the datetime has its usec field set to nil, 0 will be used for usec.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", 999999) |> Calendar.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 999999}}

      iex> from_erl!({{2014,10,15},{2,37,22}}, "Etc/UTC", nil) |> Calendar.DateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 0}}
  """
  def to_micro_erl(%Calendar.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, usec: nil}) do
    {{year, month, day}, {hour, min, sec, 0}}
  end
  def to_micro_erl(%Calendar.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, usec: usec}) do
    {{year, month, day}, {hour, min, sec, usec}}
  end
  def to_micro_erl(date_time) do
    date_time |> contained_date_time |> to_micro_erl
  end

  @doc """
  Takes a DateTime struct and returns a Date struct representing the date part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_date
      %Calendar.Date{day: 15, month: 10, year: 2014}
  """
  def to_date(%Calendar.DateTime{} = dt) do
    %Calendar.Date{year: dt.year, month: dt.month, day: dt.day}
  end
  def to_date(dt), do: dt |> contained_date_time |> to_date

  @doc """
  Takes a DateTime struct and returns a Time struct representing the time part
  of the provided DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_time
      %Calendar.Time{usec: nil, hour: 2, min: 37, sec: 22}
  """
  def to_time(%Calendar.DateTime{} = dt) do
    %Calendar.Time{hour: dt.hour, min: dt.min, sec: dt.sec, usec: dt.usec}
  end
  def to_time(dt), do: dt |> contained_date_time |> to_time

  @doc """
  Returns a tuple with a Date struct and a Time struct.

      iex> from_erl!({{2014,10,15},{2,37,22}}, "UTC") |> Calendar.DateTime.to_date_and_time
      {%Calendar.Date{day: 15, month: 10, year: 2014}, %Calendar.Time{usec: nil, hour: 2, min: 37, sec: 22}}
  """
  def to_date_and_time(%Calendar.DateTime{} = dt) do
    {to_date(dt), to_time(dt)}
  end
  def to_date_and_time(dt), do: dt |> contained_date_time |> to_date_and_time

  @doc """
  Takes an NaiveDateTime and a time zone identifier and returns a DateTime

      iex> Calendar.NaiveDateTime.from_erl!({{2014,10,15},{2,37,22}}) |> from_naive("Etc/UTC")
      {:ok, %Calendar.DateTime{abbr: "UTC", day: 15, usec: nil, hour: 2, min: 37, month: 10, sec: 22, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2014}}
  """
  def from_naive(ndt, timezone) do
    ndt |> Calendar.NaiveDateTime.to_erl
    |> from_erl(timezone)
  end

  @doc """
  Takes a DateTime and returns a NaiveDateTime

      iex> Calendar.DateTime.from_erl!({{2014,10,15},{2,37,22}}, "UTC", 0.55) |> to_naive
      %Calendar.NaiveDateTime{day: 15, usec: 0.55, hour: 2, min: 37, month: 10, sec: 22, year: 2014}
  """
  def to_naive(dt) do
    dt |> to_erl
    |> Calendar.NaiveDateTime.from_erl!(dt.usec)
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

  def gregorian_seconds_and_usec(date_time) do
    date_time = date_time |> contained_date_time
    usec = date_time.usec
    {gregorian_seconds(date_time), usec}
  end

  @doc """
  Create new DateTime struct based on a date and a time and a timezone string.

  ## Examples

      iex> from_date_and_time_and_zone({2016, 1, 8}, {14, 10, 55}, "Etc/UTC")
      {:ok, %Calendar.DateTime{day: 8, usec: nil, hour: 14, min: 10, month: 1, sec: 55, year: 2016, abbr: "UTC", timezone: "Etc/UTC", usec: nil, utc_off: 0, std_off: 0}}
  """
  def from_date_and_time_and_zone(date_container, time_container, timezone) do
    contained_time = Calendar.ContainsTime.time_struct(time_container)
    from_erl({Calendar.Date.to_erl(date_container), Calendar.Time.to_erl(contained_time)}, timezone, contained_time.usec)
  end

  @doc """
  Like `from_date_and_time_and_zone`, but returns result untagged and
  raises in case of an error or ambiguous datetime.

  ## Examples

      iex> from_date_and_time_and_zone!({2016, 1, 8}, {14, 10, 55}, "Etc/UTC")
      %Calendar.DateTime{day: 8, usec: nil, hour: 14, min: 10, month: 1, sec: 55, year: 2016, abbr: "UTC", timezone: "Etc/UTC", usec: nil, utc_off: 0, std_off: 0}
  """
  def from_date_and_time_and_zone!(date_container, time_container, timezone) do
    {:ok, result} = from_date_and_time_and_zone(date_container, time_container, timezone)
    result
  end

  defp contained_date_time(dt_container) do
    ContainsDateTime.dt_struct(dt_container)
  end

  defp validate_erl_datetime({date, time}, timezone) do
    :calendar.valid_date(date) && valid_time_part_of_datetime(date, time, timezone)
  end
  # Validate time part of a datetime
  # The date and timezone part is only used for leap seconds
  defp valid_time_part_of_datetime(date, {h, m, 60}, "Etc/UTC") do
    TimeZoneData.leap_seconds_erl |> Enum.member?({date, {h, m, 60}})
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

  @doc """
  Returns true when first is before the second.
  """
  def before?(first, second) do
    {:ok, sec, usec} = diff(first, second)
    sec < 0 || usec < 0
  end

  @doc """
  Returns true when first is after second
  """
  def after?(first, second) do
    {:ok, sec, usec} = diff(first, second)
    sec > 0 || usec > 0
  end
end

defimpl Calendar.ContainsDateTime, for: Calendar.DateTime do
  def dt_struct(data), do: data
end
