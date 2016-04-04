defmodule Calendar.Time.Parse do
  import Calendar.ParseUtil

  @doc """
  Parses ISO 8601 time strings.

  The function accepts both the extended and the basic format.

  ## Examples

      # Extended format
      iex> iso8601("13:07:58")
      {:ok, %Time{hour: 13, minute: 7, second: 58}}
      # Basic format (the basic format does not have colons)
      iex> iso8601("130758")
      {:ok, %Time{hour: 13, minute: 7, second: 58}}
      iex> iso8601("25:65:00")
      {:error, :invalid_time}
  """
  def iso8601(string) do
    captured = string |> capture_iso8601_string
    if captured do
      Calendar.Time.from_erl(erl_time_from_regex_map(captured))
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
      iex> iso8601!("13:07:58")
      %Time{hour: 13, minute: 7, second: 58}
  """
  def iso8601!(string) do
    {:ok, result} = iso8601(string)
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
