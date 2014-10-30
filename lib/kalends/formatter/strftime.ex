defmodule Kalends.Formatter.Strftime do
  @moduledoc false
  require Kalends.DateTime

  # documentation for this is in Kalends.Formatter
  def strftime(dt, string) do
    parse_for_con_specs(string)
    |> Enum.reduce(string, fn(conv_spec, new_string) -> String.replace(new_string, "%#{conv_spec}", string_for_conv_spec(dt, conv_spec)) end)
  end

  defp parse_for_con_specs(string) do
    Regex.scan(~r/\%[a-zA-Z]/, string)
    |> Enum.map fn(x) -> hd(x)|>String.replace("%","")|>String.to_atom end
  end

  # Takes for instance a DateTime for 2014-9-6 17:10:20 and :Y and returns "2014"
  defp string_for_conv_spec(dt, :y) do "#{dt.year}" |> String.slice(-2..-1) end
  defp string_for_conv_spec(dt, :Y) do "#{dt.year}"|>pad_with_zeroes(4) end
  defp string_for_conv_spec(dt, :m) do "#{dt.month}"|>pad_with_zeroes end
  defp string_for_conv_spec(dt, :e) do "#{dt.date}" end
  defp string_for_conv_spec(dt, :d) do "#{dt.date}"|>pad_with_zeroes end
  defp string_for_conv_spec(dt, :H) do "#{dt.hour}"|>pad_with_zeroes end
  defp string_for_conv_spec(dt, :M) do "#{dt.min}"|>pad_with_zeroes end
  defp string_for_conv_spec(dt, :S) do "#{dt.sec}"|>pad_with_zeroes end
  defp string_for_conv_spec(dt, :z) do iso8601_offset_part(dt) end

  defp pad_with_zeroes(subject, len\\2) do
    String.rjust("#{subject}", len, ?0)
  end

  defp iso8601_offset_part(dt) do
    total_off = dt.utc_off + dt.std_off
    sign = sign_for_offset8601(total_off)
    offset_amount_string = total_off |> secs_to_hours_mins_string
    sign<>offset_amount_string
  end
  defp sign_for_offset8601(offset) when offset < 0, do: "-"
  defp sign_for_offset8601(_), do: "+"
  defp secs_to_hours_mins_string(secs) do
    secs = abs(secs)
    hours = secs/3600.0 |> Float.floor |> trunc
    mins = rem(secs, 3600)/60.0 |> Float.floor |> trunc
    "#{hours}:#{mins|>pad_with_zeroes(2)}"
  end
end
