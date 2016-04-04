defmodule Calendar.TimeZoneData do
  alias Tzdata, as: TZSource
  @doc """
  A list of pre-compiled periods for a given zone name.
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

      iex> Calendar.TimeZoneData.zone_exists? "Pacific/Auckland"
      true
      iex> Calendar.TimeZoneData.zone_exists? "America/Sao_Paulo"
      true
      iex> Calendar.TimeZoneData.zone_exists? "Europe/Jersey"
      true
  """
  def zone_exists?("Etc/UTC"), do: true
  def zone_exists?(name), do: TZSource.zone_exists?(name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is canonical.
  Otherwise false.

      iex> Calendar.TimeZoneData.canonical_zone? "Europe/London"
      true
      iex> Calendar.TimeZoneData.canonical_zone? "Europe/Jersey"
      false
  """
  def canonical_zone?(name), do: TZSource.canonical_zone?(name)

  @doc """
  Takes the name of a zone. Returns true if zone exists and is an alias.
  Otherwise false.

      iex> Calendar.TimeZoneData.zone_alias? "Europe/Jersey"
      true
      iex> Calendar.TimeZoneData.zone_alias? "Europe/London"
      false
  """
  def zone_alias?(name), do: TZSource.zone_alias?(name)

  # Provide map of links
  @doc """
  Returns a map of links. Also known as aliases.

      iex> Calendar.TimeZoneData.links["Europe/Jersey"]
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

      Calendar.TimeZoneData.tzdata_version
      "2014i"
  """
  def tzdata_version, do: TZSource.tzdata_version

  def periods_for_time(zone_name, time_point, time_type \\ :wall) do
    TZSource.periods_for_time(zone_name, time_point, time_type)
  end

  @doc """
  List of know leap seconds as DateTime structs

  ## Example:

      iex> TimeZoneData.leap_seconds |> Enum.take(3)
      [%DateTime{zone_abbr: "UTC", day: 31, hour: 23, minute: 59, month: 12, second: 60, std_offset: 0, time_zone: "Etc/UTC", microsecond: 0, utc_offset: 0, year: 1971},
       %DateTime{zone_abbr: "UTC", day: 30, hour: 23, minute: 59, month: 6, second: 60, std_offset: 0, time_zone: "Etc/UTC", microsecond: 0, utc_offset: 0, year: 1972},
       %DateTime{zone_abbr: "UTC", day: 31, hour: 23, minute: 59, month: 12, second: 60, std_offset: 0, time_zone: "Etc/UTC", microsecond: 0, utc_offset: 0, year: 1972}]
  """
  def leap_seconds do
    TZSource.leap_seconds
    |> Enum.map(fn(dt) ->
      {{year, month, day}, {hour, minute, second}} = dt
      %DateTime{zone_abbr: "UTC", microsecond: 0, time_zone: "Etc/UTC", utc_offset: 0,
        std_offset: 0, year: year, month: month, day: day, hour: hour, minute: minute,
        second: second}
      end)
  end

  @doc """
  List of known leap seconds in erlang tuple format in UTC.

  ## Example:

      iex> TimeZoneData.leap_seconds_erl |> Enum.take(3)
      [{{1971, 12, 31}, {23, 59, 60}}, {{1972, 6, 30}, {23, 59, 60}}, {{1972, 12, 31}, {23, 59, 60}}]
  """
  def leap_seconds_erl, do: TZSource.leap_seconds
end
