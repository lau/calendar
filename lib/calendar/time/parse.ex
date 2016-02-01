defmodule Calendar.Time.Parse do
  import Calendar.ParseUtil
  alias Calendar.Time

  @doc """
  Parses ISO 8601 time strings.

  The function accepts both the extended and the basic format.

  ## Examples

      # Extended format
      iex> iso_8601("13:07:58")
      {:ok, %Calendar.Time{hour: 13, min: 7, sec: 58}}
      # Basic format (the basic format does not have colons)
      iex> iso_8601("130758")
      {:ok, %Calendar.Time{hour: 13, min: 7, sec: 58}}
      iex> iso_8601("25:65:00")
      {:error, :invalid_time}
  """
  def iso_8601(string) do
    captured = string |> capture_iso8601_string
    if captured do
      Time.from_erl(erl_time_from_regex_map(captured))
    else
      {:bad_format, nil}
    end
  end

  @doc """
  Parses ISO 8601 time strings.

  Like `iso_8601/1`, but returns the result untagged and raises
  in case of an error.

  ## Examples

      # Extended format
      iex> iso_8601!("13:07:58")
      %Calendar.Time{hour: 13, min: 7, sec: 58}
  """
  def iso_8601!(string) do
    {:ok, result} = iso_8601(string)
    result
  end

  defp capture_iso8601_string(string) do
    ~r/(?<hour>[\d]{2}):?(?<min>[\d]{2}):?(?<sec>[\d]{2})/
    |> Regex.named_captures(string)
  end

  defp erl_time_from_regex_map(mapped) do
    erl_date_time_from_strings({mapped["hour"], mapped["min"], mapped["sec"]})
  end

   defp erl_date_time_from_strings({hour, min, sec}) do
    {hour |> to_int, min |> to_int, sec |> to_int}
  end
end