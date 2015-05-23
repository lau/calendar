defmodule Calendar.DateTime.Parse do
  alias Calendar.DateTime

  @secs_between_year_0_and_unix_epoch 719528*24*3600 # From erlang calendar docs: there are 719528 days between Jan 1, 0 and Jan 1, 1970. Does not include leap seconds

  @doc """
  Takes unix time as an integer or float. Returns a DateTime struct.

  ## Examples

      iex> unix!(1_000_000_000)
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: nil, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}

      iex> unix!("1000000000")
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: nil, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}

      iex> unix!(1_000_000_000.9876)
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: 987600, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}

      iex> unix!(1_000_000_000.999999)
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: 999999, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}
  """
  def unix!(unix_time_stamp) when is_integer(unix_time_stamp) do
    unix_time_stamp + @secs_between_year_0_and_unix_epoch
    |>:calendar.gregorian_seconds_to_datetime
    |> DateTime.from_erl!("Etc/UTC")
  end
  def unix!(unix_time_stamp) when is_float(unix_time_stamp) do
    {whole, micro} = int_and_usec_for_float(unix_time_stamp)
    whole + @secs_between_year_0_and_unix_epoch
    |>:calendar.gregorian_seconds_to_datetime
    |> DateTime.from_erl!("Etc/UTC", micro)
  end
  def unix!(unix_time_stamp) when is_binary(unix_time_stamp) do
    unix_time_stamp
    |> to_int
    |> unix!
  end

  defp int_and_usec_for_float(float) do
    float_as_string = Float.to_string(float, [decimals: 6, compact: false])
    {int, frac} = Integer.parse(float_as_string)
    {int, parse_unix_fraction(frac)}
  end
  # recieves eg. ".987654321" returns usecs. eg. 987654
  defp parse_unix_fraction(string), do: String.slice(string, 1..6) |> String.ljust(6, ?0) |> Integer.parse |> elem(0)

  @doc """
  Parse JavaScript style milliseconds since epoch.

  # Examples

      iex> js_ms!("1000000000123")
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: 123000, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}

      iex> js_ms!(1_000_000_000_123)
      %Calendar.DateTime{abbr: "UTC", day: 9, usec: 123000, hour: 1, min: 46, month: 9, sec: 40, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2001}

      iex> js_ms!(1424102000000)
      %Calendar.DateTime{abbr: "UTC", day: 16, hour: 15, usec: 0, min: 53, month: 2, sec: 20, std_off: 0, timezone: "Etc/UTC", utc_off: 0, year: 2015}
  """
  def js_ms!(millisec) when is_integer(millisec) do
    (millisec/1000.0)
    |> unix!
  end

  def js_ms!(millisec) when is_binary(millisec) do
    {int, ""} = millisec
    |> Integer.parse
    js_ms!(int)
  end

  @doc """
  Parses a timestamp in RFC 2616 format.

      iex> httpdate("Sat, 06 Sep 2014 09:09:08 GMT")
      {:ok, %Calendar.DateTime{year: 2014, month: 9, day: 6, hour: 9, min: 9, sec: 8, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

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
    DateTime.from_erl(
      {
        {mapped["year"]|>to_int,
          mapped["month"]|>month_number_for_month_name,
          mapped["day"]|>to_int},
        {mapped["hour"]|>to_int, mapped["min"]|>to_int, mapped["sec"]|>to_int }
      }, "Etc/UTC")
  end
  defp month_number_for_month_name(string) do
    string
    |> String.downcase
    |> cap_month_number_for_month_name
  end
  defp cap_month_number_for_month_name("jan"), do: 1
  defp cap_month_number_for_month_name("feb"), do: 2
  defp cap_month_number_for_month_name("mar"), do: 3
  defp cap_month_number_for_month_name("apr"), do: 4
  defp cap_month_number_for_month_name("may"), do: 5
  defp cap_month_number_for_month_name("jun"), do: 6
  defp cap_month_number_for_month_name("jul"), do: 7
  defp cap_month_number_for_month_name("aug"), do: 8
  defp cap_month_number_for_month_name("sep"), do: 9
  defp cap_month_number_for_month_name("oct"), do: 10
  defp cap_month_number_for_month_name("nov"), do: 11
  defp cap_month_number_for_month_name("dec"), do: 12
  # By returning 0 for invalid month names, we have a valid int to pass to
  # DateTime.from_erl that will return a nice error. This way we avoid an
  # exception when parsing an httpdate with an invalid month name.
  defp cap_month_number_for_month_name(_), do: 0

  @doc """
  Parse RFC 3339 timestamp strings as UTC. If the timestamp is not in UTC it
  will be shifted to UTC.

  ## Examples

      iex> rfc3339_utc("fooo")
      {:bad_format, nil}

      iex> rfc3339_utc("1996-12-19T16:39:57Z")
      {:ok, %Calendar.DateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

      iex> rfc3339_utc("1996-12-19T16:39:57-08:00")
      {:ok, %Calendar.DateTime{year: 1996, month: 12, day: 20, hour: 0, min: 39, sec: 57, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

      # Offset does not have colon (-0800). That makes it ISO8601, but not RFC3339. We still parse it.
      iex> rfc3339_utc("1996-12-19T16:39:57-0800")
      {:ok, %Calendar.DateTime{year: 1996, month: 12, day: 20, hour: 0, min: 39, sec: 57, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0}}
  """
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
      {:ok, %Calendar.DateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

      iex> rfc3339("1996-12-19T16:39:57.1234Z", "Etc/UTC")
      {:ok, %Calendar.DateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, timezone: "Etc/UTC", abbr: "UTC", std_off: 0, utc_off: 0, usec: 123400}}

      iex> rfc3339("1996-12-19T16:39:57-8:00", "America/Los_Angeles")
      {:ok, %Calendar.DateTime{abbr: "PST", day: 19, hour: 16, min: 39, month: 12, sec: 57, std_off: 0, timezone: "America/Los_Angeles", utc_off: -28800, year: 1996}}

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
    utc_dt |> DateTime.shift_zone time_zone
  end

  defp parse_rfc3339_as_utc_parsed_string(mapped, z, _offset_hours, _offset_mins) when z == "Z" or z=="z" do
    parse_rfc3339_as_utc_parsed_string(mapped, "", "00", "00")
  end
  defp parse_rfc3339_as_utc_parsed_string(mapped, _z, offset_hours, offset_mins) when offset_hours == "00" and offset_mins == "00" do
    DateTime.from_erl(erl_date_time_from_regex_map(mapped), "Etc/UTC", parse_fraction(mapped["fraction"]))
  end
  defp parse_rfc3339_as_utc_parsed_string(mapped, _z, offset_hours, offset_mins) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    if mapped["offset_sign"] == "-", do: offset_in_secs = offset_in_secs*-1
    erl_date_time = erl_date_time_from_regex_map(mapped)
    parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time)
  end

  defp parse_fraction(""), do: nil
  # parse and return microseconds
  defp parse_fraction(string), do: String.slice(string, 0..5) |> String.ljust(6, ?0) |> Integer.parse |> elem(0)

  defp parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(erl_date_time)
    new_time = greg_secs - offset_in_secs
    |> :calendar.gregorian_seconds_to_datetime
    DateTime.from_erl(new_time, "Etc/UTC")
  end

  defp erl_date_time_from_regex_map(mapped) do
    erl_date_time_from_strings({{mapped["year"],mapped["month"],mapped["day"]},{mapped["hour"],mapped["min"],mapped["sec"]}})
  end

  defp erl_date_time_from_strings({{year, month, date},{hour, min, sec}}) do
    { {year|>to_int, month|>to_int, date|>to_int},
      {hour|>to_int, min|>to_int, sec|>to_int} }
  end

  defp to_int(string) do
    {int, _} = Integer.parse(string)
    int
  end

  # Takes strings of hours and mins and return secs
  defp hours_mins_to_secs!(hours, mins) do
    hours_int = hours |> to_int
    mins_int = mins |> to_int
    hours_int*3600+mins_int*60
  end

  defp parse_rfc3339_string(rfc3339_string) do
    ~r/(?<year>[\d]{4})[^\d](?<month>[\d]{2})[^\d](?<day>[\d]{2})[^\d](?<hour>[\d]{2})[^\d](?<min>[\d]{2})[^\d](?<sec>[\d]{2})(\.(?<fraction>[\d]+))?(?<z>[zZ])?((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2}):?(?<offset_mins>[\d]{2}))?/
    |> Regex.named_captures rfc3339_string
  end
end
