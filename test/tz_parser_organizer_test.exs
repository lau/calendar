defmodule TzParserOrganizerTest do
  use ExUnit.Case, async: true
  alias Kalends.TzParser, as: TzParser

  test "Zone map" do
    europe = TzParser.read_file("europe_shortened", "test/tzdata_fixtures")
    zones = TzParser.Organizer.zones(europe)
    assert zones["Europe/Copenhagen"][:name] == "Europe/Copenhagen"
  end

  test "Rule map" do
    europe = TzParser.read_file("europe")
    rules = TzParser.Organizer.rules(europe)
    assert hd(rules["Denmark"]) == %{at: {{23, 0, 0}, :wall}, from: 1916, in: 5, letter: "S", name: "Denmark", on: "14", record_type: :rule, save: 3600, to: :only, type: "-"}
  end

  test "Link map. Should have alias name as key. And canonical zone as value" do
    backward = TzParser.read_file("backward")
    links = TzParser.Organizer.links(backward)
    assert links["Iceland"] == "Atlantic/Reykjavik"
  end

  # We want a list of all the zone names.
  # It works as a list of keys so we know which zones we have available.
  # Canonical zones only
  test "Zone list" do
    europe = TzParser.read_file("europe_shortened", "test/tzdata_fixtures")
    zone_list = TzParser.Organizer.zone_list(europe)
    assert length(zone_list) == 21
    assert zone_list|>hd == "Atlantic/Faroe"
    assert zone_list|>Enum.at(20) == "WET"
  end

  # For zone links. Zone links are links to canonical zones.
  # Zone links are like an alias.
  # For instance Europe/Jersey is an "alias" for Europe/London
  test "Link list" do
    europe = TzParser.read_file("europe_shortened", "test/tzdata_fixtures")
    link_list = TzParser.Organizer.link_list(europe)
    assert length(link_list) == 4
    assert link_list|>hd == "Europe/Busingen"
    assert link_list|>Enum.at(3) == "Europe/Jersey"
  end

  # We want a list both zone and link names.
  # It should be sorted alphabetically.
  test "Zone and link list" do
    europe = TzParser.read_file("europe_shortened", "test/tzdata_fixtures")
    list = TzParser.Organizer.zone_and_link_list(europe)
    assert length(list) == 25
    assert list|>hd == "Atlantic/Faroe"
    assert list|>Enum.at(15) == "Europe/Jersey"
  end
end
