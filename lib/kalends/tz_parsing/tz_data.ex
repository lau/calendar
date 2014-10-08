defmodule Kalends.TzParsing.TzData do
  @moduledoc false
  alias Kalends.TzParsing.TzParser, as: Parser
  alias Kalends.TzParsing.TzParser.Organizer, as: Organizer
  files = ~w(africa antarctica asia australasia backward etcetera europe northamerica pacificnew southamerica)s
  all_files_read = Enum.map(files, fn elem -> Parser.read_file(elem) end) |> List.flatten
  rules = Organizer.rules(all_files_read)
  zones = Organizer.zones(all_files_read)
  links = Organizer.links(all_files_read)
  Enum.each(zones, fn {k, v} -> def zone(unquote(k)), do: {:ok, unquote(Macro.escape(v))} end)
  Enum.each(rules, fn {k, v} -> def rules(unquote(k)), do: {:ok, unquote(Macro.escape(v))} end)
  Enum.each(links, fn {k, v} -> def zone(unquote(k)), do: {:ok, unquote(Macro.escape(zones[v]))} end)
  # if a function for a specific zone or rule has not been defined, these not-found-functions will be called
  def zone(_), do: {:error, :not_found}
  def rules(_), do: {:error, :not_found}

  # Provide lists of zone- and link-names
  def zone_list, do: unquote(Macro.escape(Organizer.zone_list(all_files_read)))
  def link_list, do: unquote(Macro.escape(Organizer.link_list(all_files_read)))
  def zone_and_link_list, do: unquote(Macro.escape(Organizer.zone_and_link_list(all_files_read)))

  # Provide map of links
  def links, do: unquote(Macro.escape(links))
end
