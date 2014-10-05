defmodule Kalends.TimeZonePeriods do
  require Kalends.TimeZoneData
  alias Kalends.TimeZoneData, as: TimeZoneData

  def periods_for_time(zone_name, time_point, time_type \\ :wall) do
    {:ok, periods} = TimeZoneData.periods(zone_name)
    periods
    |> Enum.filter(fn x ->
                     ((x[:from][time_type] |>smaller_than_or_equals time_point)
                     && (x[:until][time_type] |>bigger_than time_point))
                   end)
  end

  defp smaller_than_or_equals(:min, _), do: true
  defp smaller_than_or_equals(first, second), do: first <= second
  defp bigger_than(:max, _), do: true
  defp bigger_than(first, second), do: first > second
end
