defmodule Kalends.DateTime.Format do
  alias Kalends.DateTime
  alias Kalends.DateTime.Format.Strftime
  @secs_between_year_0_and_unix_epoch 719528*24*3600 # From erlang calendar docs: there are 719528 days between Jan 1, 0 and Jan 1, 1970. Does not include leap seconds

  @doc """
  Generate a string from a DateTime formatted by a format string. Similar to strftime! known from UNIX.

  # Example
      iex> DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC") |> DateTime.Format.strftime! "%A %Y-%m-%e %H:%M:%S"
      "Saturday 2014-09- 6 17:10:20"

      iex> DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC") |> DateTime.Format.strftime! "%a %d.%m.%y"
      "Sat 06.09.14"

      iex> DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC") |> DateTime.Format.strftime! "%A %d/%m/%Y", :da
      "lørdag 06/09/2014"

      iex> DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC") |> DateTime.Format.strftime! "%A %d/%m/%Y", :es
      "sábado 06/09/2014"

  | conversion spec. | Description                                                     | Example            |
  | -----------------|:---------------------------------------------------------------:| ------------------:|
  | %a               | Abbreviated name of day                                         | _Mon_              |
  | %A               | Full name of day                                                | _Monday_           |
  | %b               | Abbreviated month name                                          | _Jan_              |
  | %h               | (Equivalent to %b)                                              |                    |
  | %B               | Full month name                                                 | _January_          |
  | %j               | Day of the year as a decimal number (001 to 366).               | _002_              |
  | %u               | Day of the week as a decimal number (1 through 7). Also see %w  | _1_ for Monday     |
  | %w               | Day of the week as a decimal number (0 through 6). Also see %u  | _0_ for Sunday     |
  | %V               | Week number (ISO 8601). (01 through 53)                         | _02_ for week 2    |
  | %G               | Year for ISO 8601 week number (see %V). Not the same as %Y!     | _2015_             |
  | %g               | 2 digit version of %G. Iso week-year. (00 through 99)           | _15_ for 2015      |
  | %y               | 2 digit version of %Y. (00 through 99)                          | _15_ for 2015      |
  | %Y               | The year in four digits. (0001 through 9999)                    | _2015_             |
  | %C               | Century number as two digits. 21st century will be 20.          | _20_ for year 2015 |
  | %I               | Hour as decimal number using 12 hour clock. (01-12)             | _07_ for 19:00     |
  | %l               | Like %I but with single digits preceded by a space.             | _7_ for 19:00     |
  | %P               | am or pm for 12 hour clock. In lower case.                      | _pm_ for 19:00     |
  | %p               | AM or PM for 12 hour clock. In upper case.                      | _PM_ for 19:00     |
  | %r               | Time in 12 hour notation. Equivalent to %I:%M:%S %p.            | _07:25:41 PM_      |
  | %R               | Time in 24 hour notation excluding seconds. Equivalent of %H:%M.| _19:25_            |
  | %T               | Time in 24 hour notation. Equivalent of %H:%M:%S.               | _19:25:41_         |
  | %F               | Date in ISO 8601 format. Equivalent of %Y-%m-%d.                | _2015-02-05_       |
  | %m               | Month as decimal number (01-12).                                | _01_ for January   |
  | %e               | Day of the month as decimal number. Leading space if 1-digit.   | _5_ for 2015-02-05|
  | %d               | Day of the month as decimal number. Leading zero. (01-31).      | _05_ for 2015-02-05|
  | %H               | Hour as decimal number using 24 hour clock (00-23).             | _08_ for 08:25     |
  | %k               | Like %H, but with leading space instead of leading zero.        | _8_ for 08:25     |
  | %M               | Minute as decimal number (00-59).                               | _04_ for 19:04     |
  | %S               | Seconds as decimal number (00-60).                              | _02_ for 19:04:02  |
  | %z               | Hour and minute timezone offset from UTC.                       | _-0200_            |
  | %Z               | Time zone abbreviation. Sometimes depends on DST.               | _UYST_             |
  """
  def strftime!(dt, string, lang\\:en) do
    Strftime.strftime!(dt, string, lang)
  end

  @doc """
  Takes a DateTime.
  Returns a string with the time in RFC3339 (a profile of ISO 8601)

  ## Example

      iex> Kalends.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo") |> Kalends.DateTime.Format.rfc3339
      "2014-09-26T17:10:20-03:00"
  """
  def rfc3339(dt) do
    Strftime.strftime!(dt, "%Y-%m-%dT%H:%M:%S")<>
    iso8601_offset_part(dt, dt.timezone)
  end

  defp iso8601_offset_part(_, time_zone) when time_zone == "UTC" or time_zone == "Etc/UTC", do: "Z"
  defp iso8601_offset_part(dt, _) do
    Strftime.strftime!(dt, "%z")
  end

  @doc """
  Takes a DateTime.
  Returns a string with the date-time in RFC 2616 format. This format is used in
  the HTTP protocol. Note that the date-time will always be "shifted" to UTC.

  ## Example

      # The time is 6:09 in the morning in Montevideo, but 9:09 GMT/UTC.
      iex> DateTime.from_erl!({{2014, 9, 6}, {6, 9, 8}}, "America/Montevideo") |> DateTime.Format.httpdate
      "Sat, 06 Sep 2014 09:09:08 GMT"
  """
  def httpdate(dt) do
    dt
    |> DateTime.shift_zone!("UTC")
    |> Strftime.strftime!("%a, %d %b %Y %H:%M:%S GMT")
  end

  @doc """
  Unix time. Unix time is defined as seconds since 1970-01-01 00:00:00 UTC without leap seconds.

  ## Examples

      iex> DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 55) |> DateTime.Format.unix
      1_000_000_000
  """
  def unix(date_time) do
    date_time
    |> DateTime.shift_zone!("UTC")
    |> DateTime.gregorian_seconds
    |> - @secs_between_year_0_and_unix_epoch
  end

  @doc """
  Like unix_time but returns a float with fractional seconds. If the microsec of the DateTime
  is nil, the fractional seconds will be treated as 0.0 as seen in the second example below:

  ## Examples

      iex> DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 985085) |> DateTime.Format.unix_micro
      1_000_000_000.985085

      iex> DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen") |> DateTime.Format.unix_micro
      1_000_000_000.0
  """
  def unix_micro(date_time = %Kalends.DateTime{microsec: microsec}) when microsec == nil do
    date_time |> unix |> + 0.0
  end
  def unix_micro(date_time) do
    date_time
    |> unix
    |> + (date_time.microsec/1_000_000)
  end

  @doc """
  Takes datetime and returns UTC timestamp in JavaScript format. That is milliseconds since 1970 unix epoch.

  ## Examples

      iex> DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 985085) |> DateTime.Format.js_ms
      1_000_000_000_985

      iex> DateTime.from_erl!({{2001,09,09},{03,46,40}}, "Europe/Copenhagen", 98508) |> DateTime.Format.js_ms
      1_000_000_000_098
  """
  def js_ms(date_time) do
    whole_secs = date_time
    |> unix
    |> Kernel.* 1000
    whole_secs + micro_to_mil(date_time.microsec)
  end

  defp micro_to_mil(microsec) do
    "#{microsec}"
     |> String.rjust(6, ?0) # pad with zeros if necessary
     |> String.slice(0..2)  # take first 3 numbers to get milliseconds
     |> Integer.parse
     |> elem(0) # return the integer part
  end
end
