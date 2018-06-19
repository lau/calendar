defmodule Calendar.DateTime.Format do
  alias Calendar.Strftime
  @secs_between_year_0_and_unix_epoch 719528*24*3600 # From erlang calendar docs: there are 719528 days between Jan 1, 0 and Jan 1, 1970. Does not include leap seconds

  @doc """
  Format a DateTime as an RFC 2822 timestamp.

  ## Examples
      iex> Calendar.DateTime.from_erl!({{2010, 3, 13}, {11, 23, 03}}, "America/Los_Angeles") |> rfc2822
      "Sat, 13 Mar 2010 11:23:03 -0800"
      iex> Calendar.DateTime.from_erl!({{2010, 3, 13}, {11, 23, 03}}, "Etc/UTC") |> rfc2822
      "Sat, 13 Mar 2010 11:23:03 +0000"
  """
  def rfc2822(dt) do
    dt
    |> contained_date_time
    |> Strftime.strftime!("%a, %d %b %Y %T %z")
  end

  @doc """
  Format a DateTime as an RFC 822 timestamp.

  Note that this format is old and uses only 2 digits to denote the year!

  ## Examples
      iex> Calendar.DateTime.from_erl!({{2010, 3, 13}, {11, 23, 03}}, "America/Los_Angeles") |> rfc822
      "Sat, 13 Mar 10 11:23:03 -0800"
      iex> Calendar.DateTime.from_erl!({{2010, 3, 13}, {11, 23, 03}}, "Etc/UTC") |> rfc822
      "Sat, 13 Mar 10 11:23:03 +0000"
  """
  def rfc822(dt) do
    dt
    |> contained_date_time
    |> Strftime.strftime!("%a, %d %b %y %T %z")
  end

  @doc """
  Format a DateTime as an RFC 850 timestamp.

  Note that this format is old and uses only 2 digits to denote the year!

  ## Examples
      iex> Calendar.DateTime.from_erl!({{2010, 3, 13}, {11, 23, 03}}, "America/Los_Angeles") |> rfc850
      "Sat, 13-Mar-10 11:23:03 PST"
  """
  def rfc850(dt) do
    dt
    |> contained_date_time
    |> Strftime.strftime!("%a, %d-%b-%y %T %Z")
  end

  @doc """
  Format as ISO 8601 extended (alias for rfc3339/1)
  """
  def iso8601(dt), do: rfc3339(dt)

  @doc """
  Format as ISO 8601 Basic

  # Examples

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {20, 10, 20}}, "Etc/UTC",5) |> Calendar.DateTime.Format.iso8601_basic
      "20140926T201020Z"
      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo",5) |> Calendar.DateTime.Format.iso8601_basic
      "20140926T171020-0300"
  """
  def iso8601_basic(dt) do
    dt = dt |> contained_date_time
    offset_part = rfc3339_offset_part(dt, dt.time_zone)
    |> String.replace(":", "")
    Strftime.strftime!(dt, "%Y%m%dT%H%M%S")<>offset_part
  end

  @doc """
  Takes a DateTime.
  Returns a string with the time in RFC3339 (a profile of ISO 8601)

  ## Examples

  Without microseconds

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo") |> Calendar.DateTime.Format.rfc3339
      "2014-09-26T17:10:20-03:00"

  With microseconds

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20, 5}}, "America/Montevideo") |> Calendar.DateTime.Format.rfc3339
      "2014-09-26T17:10:20.000005-03:00"
  """
  def rfc3339(%DateTime{time_zone: time_zone, year: year, month: month, day: day, hour: hour, minute: minute, second: second, microsecond: microsecond} = dt) do
    [pad(year, 4), "-", pad(month), "-", pad(day), "T", pad(hour), ":", pad(minute), ":", pad(second),
      rfc3330_microsecond_part(microsecond, nil),
      rfc3339_offset_part(dt, time_zone)]
    |> IO.iodata_to_binary
  end
  def rfc3339(dt), do: dt |> contained_date_time |> rfc3339

  defp rfc3339_offset_part(_, time_zone) when time_zone == "UTC" or time_zone == "Etc/UTC", do: "Z"
  defp rfc3339_offset_part(dt, _) do
    Strftime.strftime!(dt, "%z")
    total_off = dt.utc_offset + dt.std_offset
    sign = sign_for_offset(total_off)
    offset_amount_string = total_off |> secs_to_hours_mins_string
    sign<>offset_amount_string
  end
  defp sign_for_offset(offset) when offset < 0, do: "-"
  defp sign_for_offset(_), do: "+"
  defp secs_to_hours_mins_string(secs) do
    secs = abs(secs)
    hours = secs/3600.0 |> Float.floor |> trunc
    mins = rem(secs, 3600)/60.0 |> Float.floor |> trunc
    "#{pad(hours, 2)}:#{pad(mins, 2)}"
  end

  defp rfc3330_microsecond_part(_, 0), do: ""
  defp rfc3330_microsecond_part({microsecond, precision}, nil), do: rfc3330_microsecond_part({microsecond, precision}, precision)
  defp rfc3330_microsecond_part({microsecond, _}, 6) do
    "." <> pad(microsecond, 6)
  end
  defp rfc3330_microsecond_part({microsecond, _inherent_precision}, precision) when precision >= 1 and precision <=6 do
    ".#{microsecond |> pad(6)}" |> String.slice(0..precision)
  end

  defp pad(subject, len \\ 2, char \\ "0")
  defp pad(subject, 2, _char) when is_integer(subject) and subject >= 10 and subject <= 99 do
    Integer.to_string(subject)
  end
  defp pad(subject, len, char) when is_integer(subject) do
    subject
    |> Integer.to_string
    |> pad(len, char)
  end
  defp pad(subject, len, char) when is_binary(subject) do
    String.pad_leading(subject, len, char)
  end

  @doc """
  Takes a DateTime and a integer for number of decimals.
  Returns a string with the time in RFC3339 (a profile of ISO 8601)

  The decimal_count integer defines the number fractional second digits.
  The decimal_count must be between 0 and 6.

  Fractional seconds are not rounded up, but rather trucated.

  ## Examples

  DateTime does not have microseconds, but 3 digits of fractional seconds
  requested. We assume 0 microseconds and display three zeroes.

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo") |> Calendar.DateTime.Format.rfc3339(3)
      "2014-09-26T17:10:20.000-03:00"

  DateTime has microseconds and decimal count set to 6

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo",{5, 6}) |> Calendar.DateTime.Format.rfc3339(6)
      "2014-09-26T17:10:20.000005-03:00"

  DateTime has microseconds and decimal count set to 5

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo",{5, 6}) |> Calendar.DateTime.Format.rfc3339(5)
      "2014-09-26T17:10:20.00000-03:00"

  DateTime has microseconds and decimal count set to 0

      iex> Calendar.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo",{5, 6}) |> Calendar.DateTime.Format.rfc3339(0)
      "2014-09-26T17:10:20-03:00"
  """
  def rfc3339(%DateTime{} = dt, decimal_count) when decimal_count >= 0 and decimal_count <=6 do
    Strftime.strftime!(dt, "%Y-%m-%dT%H:%M:%S")<>
    rfc3330_microsecond_part(dt.microsecond, decimal_count)<>
    rfc3339_offset_part(dt, dt.time_zone)
  end
  def rfc3339(dt, decimal_count) do
    dt
    |> contained_date_time
    |> rfc3339(decimal_count)
  end

  @doc """
  Takes a DateTime.
  Returns a string with the date-time in RFC 2616 format. This format is used in
  the HTTP protocol. Note that the date-time will always be "shifted" to UTC.

  ## Example

      # The time is 6:09 in the morning in Montevideo, but 9:09 GMT/UTC.
      iex> Calendar.DateTime.from_erl!({{2014, 9, 6}, {6, 9, 8}}, "America/Montevideo") |> Calendar.DateTime.Format.httpdate
      "Sat, 06 Sep 2014 09:09:08 GMT"
  """
  def httpdate(%DateTime{time_zone: "Etc/UTC"} = dt) do
    Strftime.strftime!(dt, "%a, %d %b %Y %H:%M:%S GMT")
  end
  def httpdate(dt) do
    dt
    |> contained_date_time
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
    |> httpdate
  end

  @doc """
  Unix time. Unix time is defined as seconds since 1970-01-01 00:00:00 UTC without leap seconds.

  ## Examples

      iex> Calendar.DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", {55, 2}) |> Calendar.DateTime.Format.unix
      1_000_000_000
  """
  def unix(%DateTime{time_zone: "Etc/UTC"} = dt) do
    dt
    |> Calendar.DateTime.gregorian_seconds
    |> Kernel.-(@secs_between_year_0_and_unix_epoch)
  end
  def unix(dt) do
    dt
    |> contained_date_time
    |> Calendar.DateTime.shift_zone!("Etc/UTC")
    |> unix
  end

  @doc """
  Like unix_time but returns a float with fractional seconds. If the microsecond of the DateTime
  is nil, the fractional seconds will be treated as 0.0 as seen in the second example below:

  ## Examples

      iex> Calendar.DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", {985085, 6}) |> Calendar.DateTime.Format.unix_micro
      1_000_000_000.985085

      iex> Calendar.DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen") |> Calendar.DateTime.Format.unix_micro
      1_000_000_000.0
  """
  def unix_micro(%DateTime{microsecond: {microsecond, _}} = date_time) when microsecond == 0 do
    date_time
    |> unix
    |> Kernel.+(0.0)
  end
  def unix_micro(%DateTime{} = date_time) do
    {microsecond, _} = date_time.microsecond
    date_time
    |> unix
    |> Kernel.+(microsecond/1_000_000)
  end
  def unix_micro(date_time) do
    date_time |> contained_date_time |> unix_micro
  end

  @doc """
  Takes datetime and returns UTC timestamp in JavaScript format. That is milliseconds since 1970 unix epoch.

  These millisecond numbers can be used to create new Javascript Dates in JavaScript like so: new Date(1000000000985)
  The UTC value of the javascript date will be the same as that of the Elixir Calendar.DateTime.

  ## Examples

      iex> Calendar.DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 985085) |> Calendar.DateTime.Format.js_ms
      1000000000985

      iex> Calendar.DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 98508) |> Calendar.DateTime.Format.js_ms
      1000000000098
  """
  def js_ms(date_time) do
    date_time
    |> contained_date_time
    |> DateTime.to_unix(:millisecond)
  end

  @doc """
  Formats a DateTime according to [RFC5545](https://tools.ietf.org/html/rfc5545).

  ## Examples

  FORM #2 is used for UTC DateTimes.

      iex> {:ok, datetime, _} = "1998-01-19 07:00:00Z" |> DateTime.from_iso8601
      iex> Calendar.DateTime.Format.rfc5545(datetime)
      "19980119T070000Z"

  FORM #3 (WITH LOCAL TIME AND TIME ZONE REFERENCE) is used for non-UTC datetimes

      iex> {:ok, cph_datetime} = Calendar.DateTime.from_naive(~N[2001-09-09T03:46:40.985085], "Europe/Copenhagen")
      iex> Calendar.DateTime.Format.rfc5545(cph_datetime)
      "TZID=Europe/Copenhagen:20010909T034640.985085"

      iex> {:ok, ny_datetime} = Calendar.DateTime.from_naive(~N[1998-01-19T02:00:00], "America/New_York")
      iex> Calendar.DateTime.Format.rfc5545(ny_datetime)
      "TZID=America/New_York:19980119T020000"
  """
  def rfc5545(%DateTime{} = datetime) do
    # Convert datetime to NaiveDateTime for compatability with Elixir 1.3's NaiveDateTime.to_iso8601
    naive_datetime_string =
      datetime
      |> Calendar.DateTime.to_naive()
      |> NaiveDateTime.to_iso8601()
      |> String.replace(":", "")
      |> String.replace("-", "")

    add_timezone_part_for_rfc5545(datetime, naive_datetime_string)
  end

  defp add_timezone_part_for_rfc5545(%DateTime{time_zone: "Etc/UTC"}, naive_datetime_string) do
    naive_datetime_string <> "Z"
  end

  defp add_timezone_part_for_rfc5545(datetime, naive_datetime_string) do
    "TZID=" <> datetime.time_zone <> ":" <> naive_datetime_string
  end

  defp contained_date_time(dt_container) do
    Calendar.ContainsDateTime.dt_struct(dt_container)
  end
end
