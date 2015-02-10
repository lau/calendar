defmodule Kalends.TzParsing.Periods do
  @moduledoc false
  alias Kalends.TzParsing.TzData, as: TzData
  alias Kalends.TzParsing.TzPeriodBuilder, as: TzPeriodBuilder

  # For each canonical zone, calculate periods
  Enum.each TzData.zone_list, fn (zone_name) ->
    def periods(unquote(zone_name)) do
      {:ok, unquote(Macro.escape(TzPeriodBuilder.calc_periods(zone_name)))}
    end
  end

  # For each linked zone, call canonical zone
  Enum.each TzData.links, fn {alias_name, canonical_name} ->
    def periods(unquote(alias_name)) do
      periods(unquote(canonical_name))
    end
  end

  # if a periods for a zone has not been defined at this point,
  # the zone name does not exist
  @doc """
  A list of pre-compiled periods for a given zone name. This function is
  used by the TimeZonePeriods module.
  """
  def periods(_zone_name), do: {:error, :not_found}
end
