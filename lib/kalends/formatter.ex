defmodule Kalends.Formatter do
  require Kalends.DateTime

  @doc """
  Takes an unambiguous DateTime.
  Returns a string with the time in ISO 8601

  ## Example
    iex> Kalends.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo") |> elem(1) |> Kalends.Formatter.iso8601
    "2014-09-26T17:10:20-3:00"
  """
  def iso8601(dt) do
    total_off = total_utc_offset(dt)
    sign = sign_for_offset8601(total_off)
    offset_string = total_off |> secs_to_hours_mins_string
    "#{dt.year|>pad_with_zeroes(4)}-"<>
    "#{dt.month|>pad_with_zeroes(2)}-"<>
    "#{dt.date|>pad_with_zeroes(2)}"<>
    "T#{dt.hour|>pad_with_zeroes(2)}:"<>
    "#{dt.min|>pad_with_zeroes(2)}:"<>
    "#{dt.sec|>pad_with_zeroes(2)}#{sign}"<>
    offset_string
  end

  defp total_utc_offset(dt), do: dt.utc_off + dt.std_off
  defp sign_for_offset8601(offset) when offset < 0, do: "-"
  defp sign_for_offset8601(_), do: "+"
  defp pad_with_zeroes(subject, len) do
    String.rjust("#{subject}", len, ?0)
  end
  defp secs_to_hours_mins_string(secs) do
    secs = abs(secs)
    hours = secs/3600.0 |> Float.floor |> trunc
    mins = rem(secs, 3600)/60.0 |> Float.floor |> trunc
    "#{hours}:#{mins|>pad_with_zeroes(2)}"
  end
end
