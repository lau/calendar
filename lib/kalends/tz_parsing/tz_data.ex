defmodule Kalends.TzParsing.TzData do
  @moduledoc false
  alias Kalends.TzParsing.TzParser, as: Parser
  alias Kalends.TzParsing.TzParser.Organizer, as: Organizer
  file_names = ~w(africa antarctica asia australasia backward etcetera europe northamerica pacificnew southamerica)s
  all_files_read = Enum.map(file_names, fn file_name -> {String.to_atom(file_name), Parser.read_file(file_name)} end)
  all_files_flattened = all_files_read |> Enum.map(fn {_name, read_file} -> read_file end) |> List.flatten

  rules = Organizer.rules(all_files_flattened)
  zones = Organizer.zones(all_files_flattened)
  links = Organizer.links(all_files_flattened)
  Enum.each(zones, fn {k, v} -> def zone(unquote(k)), do: {:ok, unquote(Macro.escape(v))} end)
  Enum.each(rules, fn {k, v} -> def rules(unquote(k)), do: {:ok, unquote(Macro.escape(v))} end)
  Enum.each(links, fn {k, v} -> def zone(unquote(k)), do: {:ok, unquote(Macro.escape(zones[v]))} end)
  # if a function for a specific zone or rule has not been defined, these not-found-functions will be called
  def zone(_), do: {:error, :not_found}
  def rules(_), do: {:error, :not_found}

  # Provide lists of zone- and link-names
  def zone_list, do: unquote(Macro.escape(Organizer.zone_list(all_files_flattened)))
  def link_list, do: unquote(Macro.escape(Organizer.link_list(all_files_flattened)))
  def zone_and_link_list, do: unquote(Macro.escape(Organizer.zone_and_link_list(all_files_flattened)))

  # Provide map of links
  def links, do: unquote(Macro.escape(links))

  # Group by filename
  by_group = all_files_read
  |> Enum.map(fn {name, file_read} -> {name, Organizer.zone_and_link_list(file_read)} end)
  |> Enum.into Map.new
  def zones_and_links_by_groups, do: unquote(Macro.escape(by_group))
end
