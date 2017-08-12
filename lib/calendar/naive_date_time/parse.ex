defmodule Calendar.NaiveDateTime.Parse do
  import Calendar.ParseUtil

  @doc """
  Parse ASN.1 GeneralizedTime.

  Returns tuple with {:ok, [NaiveDateTime], UTC offset (optional)}

  ## Examples

      iex> "19851106210627.3" |> asn1_generalized
      {:ok, %NaiveDateTime{year: 1985, month: 11, day: 6, hour: 21, minute: 6, second: 27, microsecond: {300_000, 1}}, nil}
      iex> "19851106210627.3Z" |> asn1_generalized
      {:ok, %NaiveDateTime{year: 1985, month: 11, day: 6, hour: 21, minute: 6, second: 27, microsecond: {300_000, 1}}, 0}
      iex> "19851106210627.3-5000" |> asn1_generalized
      {:ok, %NaiveDateTime{year: 1985, month: 11, day: 6, hour: 21, minute: 6, second: 27, microsecond: {300_000, 1}}, -180000}
  """
  def asn1_generalized(string) do
    captured = string |> capture_generalized_time_string
    if captured do
      parse_captured_iso8601(captured, captured["z"], captured["offset_hours"], captured["offset_mins"])
    else
      {:bad_format, nil, nil}
    end
  end
  defp capture_generalized_time_string(string) do
    ~r/(?<year>[\d]{4})(?<month>[\d]{2})(?<day>[\d]{2})(?<hour>[\d]{2})(?<min>[\d]{2})(?<sec>[\d]{2})(\.(?<fraction>[\d]+))?(?<z>[zZ])?((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2})(?<offset_mins>[\d]{2}))?/
    |> Regex.named_captures(string)
  end

  @doc """
  Parses a "C time" string.

  ## Examples
      iex> Calendar.NaiveDateTime.Parse.asctime("Wed Apr  9 07:53:03 2003")
      {:ok, %NaiveDateTime{year: 2003, month: 4, day: 9, hour: 7, minute: 53, second: 3, microsecond: {0, 0}}}
      iex> asctime("Thu, Apr 10 07:53:03 2003")
      {:ok, %NaiveDateTime{year: 2003, month: 4, day: 10, hour: 7, minute: 53, second: 3, microsecond: {0, 0}}}
  """
  def asctime(string) do
    cap = capture_asctime_string(string)
    month_num = month_number_for_month_name(cap["month"])
    Calendar.NaiveDateTime.from_erl({{cap["year"]|>to_int, month_num, cap["day"]|>to_int}, {cap["hour"]|>to_int, cap["min"]|>to_int, cap["sec"]|>to_int}})
  end

  @doc """
  Like `asctime/1`, but returns the result without tagging it with :ok.

  ## Examples
      iex> asctime!("Wed Apr  9 07:53:03 2003")
      %NaiveDateTime{year: 2003, month: 4, day: 9, hour: 7, minute: 53, second: 3, microsecond: {0, 0}}
      iex> asctime!("Thu, Apr 10 07:53:03 2003")
      %NaiveDateTime{year: 2003, month: 4, day: 10, hour: 7, minute: 53, second: 3, microsecond: {0, 0}}
  """
  def asctime!(string) do
    {:ok, result} = asctime(string)
    result
  end

  defp capture_asctime_string(string) do
    ~r/(?<month>[^\d]{3})[\s]+(?<day>[\d]{1,2})[\s]+(?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})[^\d]?(?<year>[\d]{4})/
    |> Regex.named_captures(string)
  end

  @doc """
  Parses an ISO8601 datetime. Returns {:ok, NaiveDateTime struct, UTC offset in secods}
  In case there is no UTC offset, the third element of the tuple will be nil.

  ## Examples

      # With offset
      iex> iso8601("1996-12-19T16:39:57-0200")
      {:ok, %NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, microsecond: {0, 0}}, -7200}

      # Without offset
      iex> iso8601("1996-12-19T16:39:57")
      {:ok, %NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, microsecond: {0, 0}}, nil}

      # With fractional seconds
      iex> iso8601("1996-12-19T16:39:57.123")
      {:ok, %NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, microsecond: {123000, 3}}, nil}

      # With fractional seconds
      iex> iso8601("1996-12-19T16:39:57,123")
      {:ok, %NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, microsecond: {123000, 3}}, nil}

      # With Z denoting 0 offset
      iex> iso8601("1996-12-19T16:39:57Z")
      {:ok, %NaiveDateTime{year: 1996, month: 12, day: 19, hour: 16, minute: 39, second: 57, microsecond: {0, 0}}, 0}

      # Invalid date
      iex> iso8601("1996-13-19T16:39:57Z")
      {:error, :invalid_datetime, nil}
  """
  def iso8601(string) do
    captured = capture_iso8601_string(string)
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
    {tag, ndt} = Calendar.NaiveDateTime.from_erl(erl_date_time_from_regex_map(captured), parse_fraction(captured["fraction"]))
    {tag, ndt, nil}
  end
  defp parse_captured_iso8601(captured, _z, offset_hours, offset_mins) do
    {tag, ndt} = Calendar.NaiveDateTime.from_erl(erl_date_time_from_regex_map(captured), parse_fraction(captured["fraction"]))
    if tag == :ok do
      {:ok, offset_in_seconds} = offset_from_captured(captured, offset_hours, offset_mins)
      {tag, ndt, offset_in_seconds}
    else
      {tag, ndt, nil}
    end
  end

  defp offset_from_captured(captured, offset_hours, offset_mins) do
    offset_in_secs = hours_mins_to_secs!(offset_hours, offset_mins)
    offset_in_secs = case captured["offset_sign"] do
      "-" -> offset_in_secs*-1
      _   -> offset_in_secs
    end
    {:ok, offset_in_secs}
  end

  defp capture_iso8601_string(string) do
    ~r/(?<year>[\d]{4})[^\d]?(?<month>[\d]{2})[^\d]?(?<day>[\d]{2})[^\d](?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})([\.\,](?<fraction>[\d]+))?(?<z>[zZ])?((?<offset_sign>[\+\-])(?<offset_hours>[\d]{1,2}):?(?<offset_mins>[\d]{2}))?/
    |> Regex.named_captures(string)
  end

  defp erl_date_time_from_regex_map(mapped) do
    erl_date_time_from_strings({{mapped["year"],mapped["month"],mapped["day"]},{mapped["hour"],mapped["min"],mapped["sec"]}})
  end

  defp erl_date_time_from_strings({{year, month, date},{hour, min, sec}}) do
    { {year|>to_int, month|>to_int, date|>to_int},
      {hour|>to_int, min|>to_int, sec|>to_int} }
  end

  defp parse_fraction(""), do: {0, 0}
  # parse and return microseconds
  defp parse_fraction(string) do
    usec = String.slice(string, 0..5)
    |> String.pad_trailing(6, "0")
    |> Integer.parse
    |> elem(0)
    {usec, String.length(string)}
  end
end
