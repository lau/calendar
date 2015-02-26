defmodule Kalends.TimeZoneData do
  alias Tzdata.TimeZoneDataSource, as: TZSource
  @doc """
  A list of pre-compiled periods for a given zone name. This function is
  used by the TimeZonePeriods module.
  """
  def periods(zone_name), do: TZSource.periods(zone_name)

  # Provide lists of zone- and link-names
  # Note that the function names are different from TzData!
  # The term "alias" is used instead of "link"
  @doc """
  zone_list provides a list of all the zone names that can be used with
  DateTime. This includes aliases.
  """
  def zone_list, do: TZSource.zone_list

  @doc """
  Like zone_list, but excludes aliases for zones.
  """
  def canonical_zone_list, do: TZSource.canonical_zone_list

  @doc """
  A list of aliases for zone names. For instance Europe/Jersey
  is an alias for Europe/London. Aliases are also known as linked zones.
  """
  def zone_alias_list, do: TZSource.zone_alias_list

  @doc """
  Takes the name of a zone. Returns true zone exists. Otherwise false.

      iex> Kalends.TimeZoneData.zone_exists? "Pacific/Auckland"
      true
      iex> Kalends.TimeZoneData.zone_exists? "America/Sao_Paulo"
      true
      iex> Kalends.TimeZoneData.zone_exists? "Europe/Jersey"
      true
  """
  def zone_exists?(name), do: TZSource.zone_exists?(name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is canonical.
  Otherwise false.

      iex> Kalends.TimeZoneData.canonical_zone? "Europe/London"
      true
      iex> Kalends.TimeZoneData.canonical_zone? "Europe/Jersey"
      false
  """
  def canonical_zone?(name), do: TZSource.canonical_zone?(name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is an alias.
  Otherwise false.

      iex> Kalends.TimeZoneData.zone_alias? "Europe/Jersey"
      true
      iex> Kalends.TimeZoneData.zone_alias? "Europe/London"
      false
  """
  def zone_alias?(name), do: TZSource.zone_alias?(name)

  # Provide map of links
  @doc """
  Returns a map of links. Also known as aliases.

      iex> Kalends.TimeZoneData.links["Europe/Jersey"]
      "Europe/London"
  """
  def links, do: TZSource.links

  @doc """
  Returns a map with keys being group names and the values lists of
  time zone names. The group names mirror the file names used by the tzinfo
  database.
  """
  def zone_lists_grouped, do: TZSource.zone_lists_grouped

  @doc """
  Returns tzdata release version as a string.

  Example:

      Kalends.TimeZoneData.tzdata_version
      "2014i"
  """
  def tzdata_version, do: TZSource.tzdata_version

  def periods_for_time(zone_name, time_point, time_type \\ :wall) do
    TZSource.periods_for_time(zone_name, time_point, time_type)
  end
end
