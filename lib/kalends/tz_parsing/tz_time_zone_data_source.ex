defmodule Kalends.TzParsing.TimeZoneDataSource do
  alias Kalends.TzParsing.TzData
  alias Kalends.TzParsing.Periods
  alias Kalends.TzParsing.TzReleaseParser
  @moduledoc false

  # Provide lists of zone- and link-names
  # Note that the function names are different from TzData!
  # The term "alias" is used instead of "link"
  @doc """
  zone_list provides a list of all the zone names that can be used with
  DateTime. This includes aliases.
  """
  def zone_list, do: unquote(Macro.escape(TzData.zone_and_link_list))

  @doc """
  Like zone_list, but excludes aliases for zones.
  """
  def canonical_zone_list, do: unquote(Macro.escape(TzData.zone_list))

  @doc """
  A list of aliases for zone names. For instance Europe/Jersey
  is an alias for Europe/London. Aliases are also known as linked zones.
  """
  def zone_alias_list, do: unquote(Macro.escape(TzData.link_list))

  @doc """
  Takes the name of a zone. Returns true zone exists. Otherwise false.

      iex> Kalends.TimeZoneData.zone_exists? "Pacific/Auckland"
      true
      iex> Kalends.TimeZoneData.zone_exists? "America/Sao_Paulo"
      true
      iex> Kalends.TimeZoneData.zone_exists? "Europe/Jersey"
      true
  """
  def zone_exists?(name), do: Enum.member?(zone_list, name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is canonical.
  Otherwise false.

      iex> Kalends.TimeZoneData.canonical_zone? "Europe/London"
      true
      iex> Kalends.TimeZoneData.canonical_zone? "Europe/Jersey"
      false
  """
  def canonical_zone?(name), do: Enum.member?(canonical_zone_list, name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is an alias.
  Otherwise false.

      iex> Kalends.TimeZoneData.zone_alias? "Europe/Jersey"
      true
      iex> Kalends.TimeZoneData.zone_alias? "Europe/London"
      false
  """
  def zone_alias?(name), do: Enum.member?(zone_alias_list, name)

  # Provide map of links
  @doc """
  Returns a map of links. Also known as aliases.

      iex> Kalends.TimeZoneData.links["Europe/Jersey"]
      "Europe/London"
  """
  def links, do: unquote(Macro.escape(TzData.links))

  @doc """
  Returns a map with keys being group names and the values lists of
  time zone names. The group names mirror the file names used by the tzinfo
  database.
  """
  def zone_lists_grouped, do: unquote(Macro.escape(TzData.zones_and_links_by_groups))

  @doc """
  Returns tzdata release version as a string.

  Example:

      Kalends.TimeZoneData.tzdata_version
      "2014i"
  """
  def tzdata_version, do: unquote(Macro.escape(TzReleaseParser.tzdata_version))

  def periods(zone_name) do
    Periods.periods(zone_name)
  end

  @min_cache_time_point 63555753600 # 2014
  @max_cache_time_point 64376208000 # 2040
  Enum.each TzData.zone_list, fn (zone_name) ->
    {:ok, periods} = Periods.periods(zone_name)
    Enum.each periods, fn(period) ->
      if period.until.utc > @min_cache_time_point && period.from.utc < @max_cache_time_point do
        def periods_for_time(unquote(zone_name), time_point, :utc) when time_point > unquote(period.from.utc) and time_point < unquote(period.until.utc) do
          unquote(Macro.escape([period]))
        end
      end
    end
  end
  # For each linked zone, call canonical zone
  Enum.each TzData.links, fn {alias_name, canonical_name} ->
    def periods_for_time(unquote(alias_name), time_point, :utc) do
      periods_for_time(unquote(canonical_name), time_point, :utc)
    end
  end

  def periods_for_time(zone_name, time_point, time_type \\ :wall) do
    {:ok, periods} = periods(zone_name)
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
