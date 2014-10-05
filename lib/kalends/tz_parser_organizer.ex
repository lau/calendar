defmodule Kalends.TzParser.Organizer do
  @moduledoc false
  # List of zone names. Canonical zones only. No links.
  def zone_list(from_initial_pass) do
    from_initial_pass
    |>Enum.filter(fn elem -> elem.record_type == :zone end)
    |>Enum.map(fn elem -> elem.name end)
    |>Enum.sort
  end
  # List of link names.
  def link_list(from_initial_pass) do
    from_initial_pass
    |>Enum.filter(fn elem -> elem.record_type == :link end)
    |>Enum.map(fn elem -> elem.to end)
    |>Enum.sort
  end
  # Combined list of zone- and link-names
  def zone_and_link_list(from_initial_pass) do
    zone_list(from_initial_pass) ++ link_list(from_initial_pass)
    |> Enum.sort
  end

  def links(from_initial_pass) do
    link_records = filter_for_record_type(from_initial_pass, :link)
    add_links_to_map(%{}, link_records)
  end
  defp add_links_to_map(map, []), do: map
  defp add_links_to_map(map, [head|tail]) do
    map = Map.put(map, head[:to], head[:from])
    add_links_to_map(map, tail)
  end

  def zones(from_initial_pass), do: map_with_name_key(from_initial_pass, :zone)
  def rules(from_initial_pass) do
    map = empty_rules_map(from_initial_pass)
    rules = filter_for_record_type(from_initial_pass, :rule)
    add_rules_to_map(map, rules)
  end

  defp add_rules_to_map(map, []), do: map
  defp add_rules_to_map(map, [rule|tail]) do
    # add rule to rule list
    new_rule_list = map[rule[:name]] ++ [rule]
    # update map with new rule list for rule name
    map = Map.put(map, rule[:name], new_rule_list)
    add_rules_to_map(map, tail)
  end

  # Returns map with keys for all the rules and empty lists as values
  defp empty_rules_map(from_initial_pass) do
    from_initial_pass
    |> filter_for_record_type(:rule)
    |> list_of_single_value_from_map_list(:name)
    |> Enum.uniq # at this point we have a list of unique Rule names
    |> Enum.map(fn elem -> Map.put(%{}, elem, []) end)
    # after merging we have a map with Rule names as keys and empty list as vals
    |> merge_maps_in_list
  end

  defp list_of_single_value_from_map_list(list, key), do: Enum.map(list, fn elem -> elem[key] end)
  defp filter_for_record_type(list, record_type), do: Enum.filter(list, fn x -> (x[:record_type] == record_type) end)

  # Takes a list of maps. Returns map with keys that are :name of
  # the map, and values being the map
  def map_with_name_key(from_initial_pass, record_type) do
    from_initial_pass
    |> Enum.filter(fn x -> (x[:record_type] == record_type) end)
    # Build list of maps with zone name as key
    |> Enum.map(fn x -> Map.put(%{}, x[:name], x) end)
    # Merge all the maps together to one map with all the zones
    |> merge_maps_in_list
  end

  # takes a list of maps and merges them all together
  def merge_maps_in_list(list), do: merge_maps_in_list(list, %{})
  defp merge_maps_in_list([], map), do: map
  defp merge_maps_in_list([head|tail], map) do
    merge_maps_in_list(tail, Map.merge(head, map))
  end
end
