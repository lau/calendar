defmodule Calendar.NaiveDateTime.Parse do
  alias Calendar.NaiveDateTime
  import Calendar.ParseUtil

  @doc """
  Parses a "C time" string.

  ## Examples
      iex> Calendar.NaiveDateTime.Parse.asctime("Wed Apr  9 07:53:03 2003")
      {:ok, %Calendar.NaiveDateTime{year: 2003, month: 4, day: 9, hour: 7, min: 53, sec: 3, usec: nil}}
      iex> asctime("Thu, Apr 10 07:53:03 2003")
      {:ok, %Calendar.NaiveDateTime{year: 2003, month: 4, day: 10, hour: 7, min: 53, sec: 3, usec: nil}}
  """
  def asctime(string) do
    cap = string |> capture_asctime_string
    month_num = month_number_for_month_name(cap["month"])
    cap
    NaiveDateTime.from_erl({{cap["year"]|>to_int, month_num, cap["day"]|>to_int}, {cap["hour"]|>to_int, cap["min"]|>to_int, cap["sec"]|>to_int}})
  end

  defp capture_asctime_string(string) do
    ~r/(?<month>[^\d]{3})[\s]+(?<day>[\d]{1,2})[\s]+(?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})[^\d]?(?<year>[\d]{4})/
    |> Regex.named_captures string
  end

  @doc """
  Parses an ISO8601 datetime. Returns {:ok, NaiveDateTime struct, UTC offset in secods}
  In case there is no UTC offset, the third element of the tuple will be nil.

  ## Examples

      # With offset
      iex> iso8601("1996-12-19T16:39:57-0200")
      {:ok, %Calendar.NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, usec: nil}, -7200}

      # Without offset
      iex> iso8601("1996-12-19T16:39:57")
      {:ok, %Calendar.NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, usec: nil}, nil}

      # With Z denoting 0 offset
      iex> iso8601("1996-12-19T16:39:57Z")
      {:ok, %Calendar.NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, min: 39, sec: 57, usec: nil}, 0}

      # Invalid date
      iex> iso8601("1996-13-19T16:39:57Z")
      {:error, :invalid_datetime, nil}
  """
  def iso8601(string) do
    captured = string |> capture_iso8601_string
    if captured do
      parse_captured_iso8601(captured, captured["z"], captured["offset_hours"], captured["offset_mins"])
    else
      {:bad_format, nil, nil}
    end
  end

  defp parse_captured_iso8601(captured, z, _, _) when z != "" do
    parse_captured_iso8601(captured, "", "00", "00")
  end
  defp parse_captured_iso8601(captured, _z, "", "") do
    {tag, ndt} = NaiveDateTime.from_erl(erl_date_time_from_regex_map(captured), parse_fraction(captured["fraction"]))
    {tag, ndt, nil}
  end
  defp parse_captured_iso8601(captured, _z, offset_hours, offset_mins) do
    {tag, ndt} = NaiveDateTime.from_erl(erl_date_time_from_regex_map(captured), parse_fraction(captured["fraction"]))
    if tag == :ok do
      {:ok, offset_in_seconds} = offset_from_captured(captured, offset_hours, offset_mins)
      {tag, ndt, offset_in_seconds}
    else
      {tag, ndt, nil}
    end
  end

  defp offset_from_captured(captured, offset_hours, offset_mins) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    if captured["offset_sign"] == "-", do: offset_in_secs = offset_in_secs*-1
    {:ok, offset_in_secs}
  end

  defp capture_iso8601_string(string) do
    ~r/(?<year>[\d]{4})[^\d]?(?<month>[\d]{2})[^\d]?(?<day>[\d]{2})[^\d](?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})(\.(?<fraction>[\d]+))?(?<z>[zZ])?((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2}):?(?<offset_mins>[\d]{2}))?/
    |> Regex.named_captures string
  end

  defp erl_date_time_from_regex_map(mapped) do
    erl_date_time_from_strings({{mapped["year"],mapped["month"],mapped["day"]},{mapped["hour"],mapped["min"],mapped["sec"]}})
  end

  defp erl_date_time_from_strings({{year, month, date},{hour, min, sec}}) do
    { {year|>to_int, month|>to_int, date|>to_int},
      {hour|>to_int, min|>to_int, sec|>to_int} }
  end

  defp parse_fraction(""), do: nil
  # parse and return microseconds
  defp parse_fraction(string), do: String.slice(string, 0..5) |> String.ljust(6, ?0) |> Integer.parse |> elem(0)
end
