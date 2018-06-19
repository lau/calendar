defmodule Calendar.DateTime.Parse do
  import Calendar.ParseUtil

  @secs_between_year_0_and_unix_epoch 719528*24*3600 # From erlang calendar docs: there are 719528 days between Jan 1, 0 and Jan 1, 1970. Does not include leap seconds


  @doc """
  Parses an RFC 822 datetime string and shifts it to UTC.

  Takes an RFC 822 `string` and `year_guessing_base`. The `year_guessing_base`
  argument is used in case of a two digit year which is allowed in RFC 822.
  The function tries to guess possible four digit versions of the year and
  chooses the one closest to `year_guessing_base`. It defaults to 2015.

  # Examples
      # 2 digit year
      iex> "5 Jul 15 20:26:13 PST" |> rfc822_utc
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 6, hour: 4, minute: 26, month: 7,
             second: 13, std_offset: 0, time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0,
             year: 2015}}
      # 82 as year
      iex> "5 Jul 82 20:26:13 PST" |> rfc822_utc
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 6, hour: 4, minute: 26, month: 7,
             second: 13, std_offset: 0, time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0,
             year: 1982}}
      # 1982 as year
      iex> "5 Jul 82 20:26:13 PST" |> rfc822_utc
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 6, hour: 4, minute: 26, month: 7,
             second: 13, std_offset: 0, time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0,
             year: 1982}}
      # 2 digit year and we use 2099 as the base guessing year
      # which means that 15 should be interpreted as 2115 no 2015
      iex> "5 Jul 15 20:26:13 PST" |> rfc822_utc(2099)
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 6, hour: 4, minute: 26, month: 7,
             second: 13, std_offset: 0, time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0,
             year: 2115}}
  """
  def rfc822_utc(string, year_guessing_base \\ 2015) do
    string
    |> capture_rfc822_string
    |> change_captured_year_to_four_digit(year_guessing_base)
    |> rfc2822_utc_from_captured
  end
  defp capture_rfc822_string(string) do
    ~r/(?<day>[\d]{1,2})[\s]+(?<month>[^\d]{3})[\s]+(?<year>[\d]{2,4})[\s]+(?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})[^\d]?(((?<offset_sign>[+-])(?<offset_hours>[\d]{2})(?<offset_mins>[\d]{2})|(?<offset_letters>[A-Z]{1,3})))?/
    |> Regex.named_captures(string)
  end
  defp change_captured_year_to_four_digit(cap, year_guessing_base) do
    changed_year = to_int(cap["year"])
    |> two_to_four_digit_year(year_guessing_base)
    |> to_string
    %{cap | "year" => changed_year}
  end

  @doc """
  Parses an RFC 2822 or RFC 1123 datetime string.

  The datetime is shifted to UTC.

  ## Examples
      iex> rfc2822_utc("Sat, 13 Mar 2010 11:23:03 -0800")
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 13, hour: 19, minute: 23, month: 3, second: 3, std_offset: 0,
             time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0, year: 2010}}

      # PST is the equivalent of -0800 in the RFC 2822 standard
      iex> rfc2822_utc("Sat, 13 Mar 2010 11:23:03 PST")
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 13, hour: 19, minute: 23, month: 3, second: 3, std_offset: 0,
             time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0, year: 2010}}

      # Z is the equivalent of UTC
      iex> rfc2822_utc("Sat, 13 Mar 2010 11:23:03 Z")
      {:ok,
            %DateTime{zone_abbr: "UTC", day: 13, hour: 11, minute: 23, month: 3, second: 3, std_offset: 0,
             time_zone: "Etc/UTC", microsecond: {0, 0}, utc_offset: 0, year: 2010}}
  """
  def rfc2822_utc(string) do
    string
    |> capture_rfc2822_string
    |> rfc2822_utc_from_captured
  end

  defp rfc2822_utc_from_captured(cap) do
    month_num = month_number_for_month_name(cap["month"])
    {:ok, offset_in_secs} = offset_in_seconds_rfc2822(cap["offset_sign"],
                                               cap["offset_hours"],
                                               cap["offset_mins"],
                                               cap["offset_letters"])
    {:ok, result} = Calendar.DateTime.from_erl({{cap["year"]|>to_int, month_num, cap["day"]|>to_int}, {cap["hour"]|>to_int, cap["min"]|>to_int, cap["sec"]|>to_int}}, "Etc/UTC")
    Calendar.DateTime.add(result, offset_in_secs*-1)
  end

  defp offset_in_seconds_rfc2822(_, _, _, "UTC"), do: {:ok, 0 }
  defp offset_in_seconds_rfc2822(_, _, _, "UT"),  do: {:ok, 0 }
  defp offset_in_seconds_rfc2822(_, _, _, "Z"),   do: {:ok, 0 }
  defp offset_in_seconds_rfc2822(_, _, _, "GMT"), do: {:ok, 0 }
  defp offset_in_seconds_rfc2822(_, _, _, "EDT"), do: {:ok, -4*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "EST"), do: {:ok, -5*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "CDT"), do: {:ok, -5*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "CST"), do: {:ok, -6*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "MDT"), do: {:ok, -6*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "MST"), do: {:ok, -7*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "PDT"), do: {:ok, -7*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, "PST"), do: {:ok, -8*3600 }
  defp offset_in_seconds_rfc2822(_, _, _, letters) when letters != "", do: {:error, :invalid_letters}
  defp offset_in_seconds_rfc2822(offset_sign, offset_hours, offset_mins, _letters) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    offset_in_secs = case offset_sign do
      "-" -> offset_in_secs*-1
      _   -> offset_in_secs
    end
    {:ok, offset_in_secs}
  end

  @doc """
  Takes unix time as an integer or float. Returns a DateTime struct.

  ## Examples

      iex> unix!(1_000_000_000)
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {0, 0}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> unix!("1000000000")
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {0, 0}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> unix!("1000000000.010")
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {10_000, 3}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> unix!(1_000_000_000.9876)
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {987600, 6}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> unix!(1_000_000_000.999999)
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {999999, 6}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}
  """
  def unix!(unix_time_stamp) when is_integer(unix_time_stamp) do
    unix_time_stamp + @secs_between_year_0_and_unix_epoch
    |>:calendar.gregorian_seconds_to_datetime
    |> Calendar.DateTime.from_erl!("Etc/UTC")
  end
  def unix!(unix_time_stamp) when is_float(unix_time_stamp) do
    {whole, micro} = int_and_microsecond_for_float(unix_time_stamp)
    whole + @secs_between_year_0_and_unix_epoch
    |>:calendar.gregorian_seconds_to_datetime
    |> Calendar.DateTime.from_erl!("Etc/UTC", micro)
  end
  def unix!(unix_time_stamp) when is_binary(unix_time_stamp) do
    {int, frac} = Integer.parse(unix_time_stamp)
    unix!(int) |> Map.put(:microsecond, parse_fraction(frac))
  end

  defp int_and_microsecond_for_float(float) do
    float_as_string = :erlang.float_to_binary(float, [decimals: 6])
    {int, frac} = Integer.parse(float_as_string)
    {int, parse_fraction(frac)}
  end

  @doc """
  Parse JavaScript style milliseconds since epoch.

  # Examples

      iex> js_ms!("1000000000123")
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {123000,3}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> js_ms!(1_000_000_000_123)
      %DateTime{zone_abbr: "UTC", day: 9, microsecond: {123000,3}, hour: 1, minute: 46, month: 9, second: 40, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2001}

      iex> js_ms!(1424102000000)
      %DateTime{zone_abbr: "UTC", day: 16, hour: 15, microsecond: {0, 3}, minute: 53, month: 2, second: 20, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2015}
  """
  def js_ms!(millisec) when is_integer(millisec) do
    result = (millisec/1000.0) |> unix!
    %DateTime{result| microsecond: {elem(result.microsecond, 0), 3}} # change usec precision to 3
  end

  def js_ms!(millisec) when is_binary(millisec) do
    {int, ""} = millisec
    |> Integer.parse
    js_ms!(int)
  end

  @doc """
  Parses a timestamp in RFC 2616 format.

      iex> httpdate("Sat, 06 Sep 2014 09:09:08 GMT")
      {:ok, %DateTime{year: 2014, month: 9, day: 6, hour: 9, minute: 9, second: 8, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0, microsecond: {0, 0}}}

      iex> httpdate("invalid")
      {:bad_format, nil}

      iex> httpdate("Foo, 06 Foo 2014 09:09:08 GMT")
      {:error, :invalid_datetime}
  """
  def httpdate(rfc2616_string) do
    ~r/(?<weekday>[^\s]{3}),\s(?<day>[\d]{2})\s(?<month>[^\s]{3})[\s](?<year>[\d]{4})[^\d](?<hour>[\d]{2})[^\d](?<min>[\d]{2})[^\d](?<sec>[\d]{2})\sGMT/
    |> Regex.named_captures(rfc2616_string)
    |> httpdate_parsed
  end
  defp httpdate_parsed(nil), do: {:bad_format, nil}
  defp httpdate_parsed(mapped) do
    Calendar.DateTime.from_erl(
      {
        {mapped["year"]|>to_int,
          mapped["month"]|>month_number_for_month_name,
          mapped["day"]|>to_int},
        {mapped["hour"]|>to_int, mapped["min"]|>to_int, mapped["sec"]|>to_int }
      }, "Etc/UTC")
  end

  @doc """
  Like `httpdate/1`, but returns the result without tagging it with :ok
  in case of success. In case of errors it raises.

      iex> httpdate!("Sat, 06 Sep 2014 09:09:08 GMT")
      %DateTime{year: 2014, month: 9, day: 6, hour: 9, minute: 9, second: 8, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}
  """
  def httpdate!(rfc2616_string) do
    {:ok, dt} = httpdate(rfc2616_string)
    dt
  end

  @doc """
  Parse RFC 3339 timestamp strings as UTC. If the timestamp is not in UTC it
  will be shifted to UTC.

  ## Examples

      iex> rfc3339_utc("fooo")
      {:bad_format, nil}

      iex> rfc3339_utc("1996-12-19T16:39:57")
      {:bad_format, nil}

      iex> rfc3339_utc("1996-12-19T16:39:57Z")
      {:ok, %DateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}}

      iex> rfc3339_utc("1996-12-19T16:39:57.123Z")
      {:ok, %DateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0, microsecond: {123000, 3}}}

      iex> rfc3339_utc("1996-12-19T16:39:57,123Z")
      {:ok, %DateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0, microsecond: {123000, 3}}}

      iex> rfc3339_utc("1996-12-19T16:39:57-08:00")
      {:ok, %DateTime{year: 1996, month: 12, day: 20, hour: 0, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}}

      # No seperation chars between numbers. Not RFC3339, but we still parse it.
      iex> rfc3339_utc("19961219T163957-08:00")
      {:ok, %DateTime{year: 1996, month: 12, day: 20, hour: 0, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}}

      # Offset does not have colon (-0800). That makes it ISO8601, but not RFC3339. We still parse it.
      iex> rfc3339_utc("1996-12-19T16:39:57-0800")
      {:ok, %DateTime{year: 1996, month: 12, day: 20, hour: 0, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}}
  """
  def rfc3339_utc(<<year::4-bytes, ?-, month::2-bytes , ?-, day::2-bytes , ?T, hour::2-bytes, ?:, min::2-bytes, ?:, sec::2-bytes, ?Z>>) do
    # faster version for certain formats of of RFC3339
    {{year|>to_int, month|>to_int, day|>to_int},{hour|>to_int, min|>to_int, sec|>to_int}} |> Calendar.DateTime.from_erl("Etc/UTC")
  end
  def rfc3339_utc(rfc3339_string) do
    parsed = rfc3339_string
    |> parse_rfc3339_string
    if parsed do
      parse_rfc3339_as_utc_parsed_string(parsed, parsed["z"], parsed["offset_hours"], parsed["offset_mins"])
    else
      {:bad_format, nil}
    end
  end

  @doc """
  Parses an RFC 3339 timestamp and shifts it to
  the specified time zone.

      iex> rfc3339("1996-12-19T16:39:57Z", "Etc/UTC")
      {:ok, %DateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0}}

      iex> rfc3339("1996-12-19T16:39:57.1234Z", "Etc/UTC")
      {:ok, %DateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, time_zone: "Etc/UTC", zone_abbr: "UTC", std_offset: 0, utc_offset: 0, microsecond: {123400, 4}}}

      iex> rfc3339("1996-12-19T16:39:57-8:00", "America/Los_Angeles")
      {:ok, %DateTime{zone_abbr: "PST", day: 19, hour: 16, minute: 39, month: 12, second: 57, std_offset: 0, time_zone: "America/Los_Angeles", utc_offset: -28800, year: 1996}}

      iex> rfc3339("1996-12-19T16:39:57.1234-8:00", "America/Los_Angeles")
      {:ok, %DateTime{zone_abbr: "PST", day: 19, hour: 16, minute: 39, month: 12, second: 57, std_offset: 0, time_zone: "America/Los_Angeles", utc_offset: -28800, year: 1996, microsecond: {123400, 4}}}

      iex> rfc3339("invalid", "America/Los_Angeles")
      {:bad_format, nil}

      iex> rfc3339("1996-12-19T16:39:57-08:00", "invalid time zone name")
      {:invalid_time_zone, nil}
  """
  def rfc3339(rfc3339_string, "Etc/UTC") do
    rfc3339_utc(rfc3339_string)
  end
  def rfc3339(rfc3339_string, time_zone) do
    rfc3339_utc(rfc3339_string) |> do_parse_rfc3339_with_time_zone(time_zone)
  end
  defp do_parse_rfc3339_with_time_zone({utc_tag, _utc_dt}, _time_zone) when utc_tag != :ok do
    {utc_tag, nil}
  end
  defp do_parse_rfc3339_with_time_zone({_utc_tag, utc_dt}, time_zone) do
    utc_dt |> Calendar.DateTime.shift_zone(time_zone)
  end

  defp parse_rfc3339_as_utc_parsed_string(mapped, z, _offset_hours, _offset_mins) when z == "Z" or z=="z" do
    parse_rfc3339_as_utc_parsed_string(mapped, "", "00", "00")
  end
  defp parse_rfc3339_as_utc_parsed_string(mapped, _z, offset_hours, offset_mins) when offset_hours == "00" and offset_mins == "00" do
    Calendar.DateTime.from_erl(erl_date_time_from_regex_map(mapped), "Etc/UTC", parse_fraction(mapped["fraction"]))
  end
  defp parse_rfc3339_as_utc_parsed_string(mapped, _z, offset_hours, offset_mins) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    offset_in_secs = case mapped["offset_sign"] do
      "-" -> offset_in_secs*-1
      _   -> offset_in_secs
    end
    erl_date_time = erl_date_time_from_regex_map(mapped)
    parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time, parse_fraction(mapped["fraction"]))
  end


  @doc """
  Parses an RFC 5545 datetime string of FORM #2 (UTC) or #3 (with time zone identifier)

  ## Examples

  FORM #2 with a Z at the end to indicate UTC

      iex> rfc5545("19980119T020321Z")
      {:ok, %DateTime{calendar: Calendar.ISO, day: 19, hour: 2, microsecond: {0, 0}, minute: 3, month: 1, second: 21, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 1998, zone_abbr: "UTC"}}

  FORM #3 has a time zone identifier

      iex> rfc5545("TZID=America/New_York:19980119T020000")
      {:ok, %DateTime{calendar: Calendar.ISO, day: 19, hour: 2, microsecond: {0, 0}, minute: 0, month: 1, second: 0, std_offset: 0, time_zone: "America/New_York", utc_offset: -18000, year: 1998, zone_abbr: "EST"}}


  From RFC 5455: "If, based on the definition of the referenced time zone, the local
  time described occurs more than once (when changing from daylight
  to standard time), the DATE-TIME value refers to the first
  occurrence of the referenced time.  Thus, TZID=America/New_York:20071104T013000
  indicates November 4, 2007 at 1:30 A.M. EDT (UTC-04:00)."

      iex> rfc5545("TZID=America/New_York:20071104T013000")
      {:ok, %DateTime{calendar: Calendar.ISO,
               day: 4, hour: 1, microsecond: {0, 0}, minute: 30, month: 11, second: 0,
               std_offset: 3600, time_zone: "America/New_York", utc_offset: -18000, year: 2007,
               zone_abbr: "EDT"}}

      iex> rfc5545("TZID=America/New_York:19980119T020000.123456")
      {:ok, %DateTime{calendar: Calendar.ISO, day: 19, hour: 2, microsecond: {123456, 6}, minute: 0, month: 1, second: 0, std_offset: 0, time_zone: "America/New_York", utc_offset: -18000, year: 1998, zone_abbr: "EST"}}


  RFC 5545 : "If the local time described does not occur (when
      changing from standard to daylight time), the DATE-TIME value is
      interpreted using the UTC offset before the gap in local times.
      Thus, TZID=America/New_York:20070311T023000 indicates March 11,
      2007 at 3:30 A.M. EDT (UTC-04:00), one hour after 1:30 A.M. EST
      (UTC-05:00)."

  The way this is implemented:
  When there is a gap for "spring forward" the difference between the two offsets before and after is added.
  E.g. usually the difference in offset between summer and winter time is one hour. Then one hour is added.

      iex> rfc5545("TZID=America/New_York:20070311T023000")
      {:ok, %DateTime{calendar: Calendar.ISO,
               day: 11, hour: 3, microsecond: {0, 0}, minute: 30, month: 3, second: 0,
               std_offset: 3600, time_zone: "America/New_York", utc_offset: -18000, year: 2007,
               zone_abbr: "EDT"}}
  """
  def rfc5545(
        <<year::4-bytes, month::2-bytes, day::2-bytes, ?T, hour::2-bytes, min::2-bytes,
          sec::2-bytes, ?Z>>
      ) do
    {{year |> to_int, month |> to_int, day |> to_int},
     {hour |> to_int, min |> to_int, sec |> to_int}}
    |> Calendar.DateTime.from_erl("Etc/UTC")
  end

  def rfc5545("TZID=" <> string) do
    [tz, iso8601] = String.split(string, ":")
    {:ok, dt, nil} = Calendar.NaiveDateTime.Parse.iso8601(iso8601)

    case Calendar.DateTime.from_erl(Calendar.NaiveDateTime.to_erl(dt), tz, dt.microsecond) do
      {:ambiguous, %Calendar.AmbiguousDateTime{possible_date_times: possible_date_times}} ->
        # Per the RFC, if the datetime happens more than once, choose the first one.
        # The first one is the one with the highest total offset. So they are sorted by
        # total offset (UTC and standard offsets) and the highest value is chosen.
        chosen_dt =
          possible_date_times
          |> Enum.sort_by(fn dt -> dt.utc_offset + dt.std_offset end)
          |> List.last()
        {:ok, chosen_dt}

      {:error, :invalid_datetime_for_timezone} ->
        most_recent_datetime_before_gap(dt, tz)

      not_ambiguous ->
        not_ambiguous
    end
  end

  defp most_recent_datetime_before_gap(naive_datetime, time_zone) do
    case Calendar.DateTime.from_erl(
           Calendar.NaiveDateTime.to_erl(naive_datetime),
           time_zone,
           naive_datetime.microsecond
         ) do
      {:ok, naive_datetime} ->
        # If there is no gap, just return the valid DateTime
        {:ok, naive_datetime}

      {:error, :invalid_datetime_for_timezone} ->
        dt_before =
          naive_datetime
          # We assume there is a gap and there is no previous gap 26 hours before
          |> NaiveDateTime.add(-3600 * 26)
          |> NaiveDateTime.to_erl()
          |> Calendar.DateTime.from_erl!(time_zone, naive_datetime.microsecond)

        dt_after =
          naive_datetime
          # We assume there is a gap and there is no additional gap 26 hours after
          |> NaiveDateTime.add(3600 * 26)
          |> NaiveDateTime.to_erl()
          |> Calendar.DateTime.from_erl!(time_zone, naive_datetime.microsecond)

        offset_difference =
          (dt_before.utc_offset + dt_before.std_offset) -
            (dt_after.utc_offset + dt_after.std_offset)
          |> abs

        naive_datetime
        |> NaiveDateTime.add(offset_difference)
        |> NaiveDateTime.to_erl()
        |> Calendar.DateTime.from_erl(time_zone, naive_datetime.microsecond)
    end
  end

  defp parse_fraction("." <> frac), do: parse_fraction(frac)
  defp parse_fraction("," <> frac), do: parse_fraction(frac)
  defp parse_fraction(""), do: {0, 0}
  # parse and return microseconds
  defp parse_fraction(string) do
    usec = String.slice(string, 0..5)
      |> String.pad_trailing(6, "0")
      |> Integer.parse
      |> elem(0)
    {usec, min(String.length(string), 6)}
  end

  defp parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time, fraction) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(erl_date_time)
    new_time = greg_secs - offset_in_secs
    |> :calendar.gregorian_seconds_to_datetime
    Calendar.DateTime.from_erl(new_time, "Etc/UTC", fraction)
  end

  defp erl_date_time_from_regex_map(mapped) do
    erl_date_time_from_strings({{mapped["year"],mapped["month"],mapped["day"]},{mapped["hour"],mapped["min"],mapped["sec"]}})
  end

  defp erl_date_time_from_strings({{year, month, date},{hour, min, sec}}) do
    { {year|>to_int, month|>to_int, date|>to_int},
      {hour|>to_int, min|>to_int, sec|>to_int} }
  end

  defp parse_rfc3339_string(rfc3339_string) do
    ~r/(?<year>[\d]{4})[^\d]?(?<month>[\d]{2})[^\d]?(?<day>[\d]{2})[^\d](?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})([\.\,](?<fraction>[\d]+))?((?<z>[zZ])|((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2}):?(?<offset_mins>[\d]{2})))/
    |> Regex.named_captures(rfc3339_string)
  end
end
