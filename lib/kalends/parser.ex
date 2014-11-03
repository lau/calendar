defmodule Kalends.Parser do
  require Kalends.DateTime
  alias Kalends.DateTime, as: DateTime

  @privatedoc """
  Parse RFC 3339 timestamp strings as UTC. If the timestamp is not in UTC it
  will be shifted to UTC.

  ## Examples

      iex> parse_rfc3339_as_utc("fooo")
      {:bad_format, nil}

      iex> parse_rfc3339_as_utc("1996-12-19T16:39:57Z")
      {:ok, %Kalends.DateTime{year: 1996, month: 12, date: 19, hour: 16, min: 39, sec: 57, timezone: "UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

      iex> parse_rfc3339_as_utc("1996-12-19T16:39:57-08:00")
      {:ok, %Kalends.DateTime{year: 1996, month: 12, date: 20, hour: 0, min: 39, sec: 57, timezone: "UTC", abbr: "UTC", std_off: 0, utc_off: 0}}
  """
  defp parse_rfc3339_as_utc(rfc3339_string) do
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

      iex> parse_rfc3339("1996-12-19T16:39:57Z", "UTC")
      {:ok, %Kalends.DateTime{year: 1996, month: 12, date: 19, hour: 16, min: 39, sec: 57, timezone: "UTC", abbr: "UTC", std_off: 0, utc_off: 0}}

      iex> parse_rfc3339("1996-12-19T16:39:57-8:00", "America/Los_Angeles")
      {:ok, %Kalends.DateTime{abbr: "PST", date: 19, hour: 16, min: 39, month: 12, sec: 57, std_off: 0, timezone: "America/Los_Angeles", utc_off: -28800, year: 1996}}

      iex> parse_rfc3339("invalid", "America/Los_Angeles")
      {:bad_format, nil}

      iex> parse_rfc3339("1996-12-19T16:39:57-08:00", "invalid time zone name")
      {:invalid_time_zone, nil}
  """
  def parse_rfc3339(rfc3339_string, "UTC") do
    parse_rfc3339_as_utc(rfc3339_string)
  end
  def parse_rfc3339(rfc3339_string, time_zone) do
    parse_rfc3339_as_utc(rfc3339_string) |> do_parse_rfc3339_with_time_zone(time_zone)
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
    {tag, dt} = DateTime.from_erl(erl_date_time_from_regex_map(mapped), "UTC")
    {tag, dt}
  end
  defp parse_rfc3339_as_utc_parsed_string(mapped, _z, offset_hours, offset_mins) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    if mapped["offset_sign"] == "-", do: offset_in_secs = offset_in_secs*-1
    erl_date_time = erl_date_time_from_regex_map(mapped)
    parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time)
  end

  defp parse_rfc3339_as_utc_with_offset(offset_in_secs, erl_date_time) do
    greg_secs = :calendar.datetime_to_gregorian_seconds(erl_date_time)
    new_time = greg_secs - offset_in_secs
    |> :calendar.gregorian_seconds_to_datetime
    DateTime.from_erl(new_time, "UTC")
  end

  defp erl_date_time_from_regex_map(mapped) do
    erl_date_time_from_strings({{mapped["year"],mapped["month"],mapped["date"]},{mapped["hour"],mapped["min"],mapped["sec"]}})
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
    ~r/(?<year>[\d]{4})[^\d](?<month>[\d]{2})[^\d](?<date>[\d]{2})[^\d](?<hour>[\d]{2})[^\d](?<min>[\d]{2})[^\d](?<sec>[\d]{2})(\.(?<fraction>[\d]))?(?<z>[zZ])?((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2}):(?<offset_mins>[\d]{2}))?/
    |> Regex.named_captures rfc3339_string
  end
end
