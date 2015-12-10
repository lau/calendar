defmodule TimeZoneDataTest do
  use ExUnit.Case, async: true
  alias Calendar.TimeZoneData, as: TimeZoneData
  doctest Calendar.TimeZoneData

  test "get periods for a cononical zone name" do
    {:ok, periods} = TimeZoneData.periods("Europe/Copenhagen")
    assert periods|>length > 1
  end

  test "get periods for a linked zone name" do
    {:ok, periods} = TimeZoneData.periods("Europe/Jersey")
    assert periods|>length > 1
  end

  test "trying to get periods for a non existing zone name should return error tuple" do
    {:error, :not_found} = TimeZoneData.periods("Fantasy/Narnia")
  end

  test "list of all zones" do
    list = TimeZoneData.zone_list
    assert list |> Enum.member?("Europe/Copenhagen")
    assert list |> Enum.member?("Europe/Jersey")
    assert !(list |> Enum.member?("Fantasy/Narnia"))
  end

  test "list of linked aka. alias zones" do
    list = TimeZoneData.zone_alias_list
    assert !(list |> Enum.member?("Europe/Copenhagen"))
    assert list |> Enum.member?("Europe/Jersey")
    assert !(list |> Enum.member?("Fantasy/Narnia"))
  end

  test "list of canonical zones" do
    list = TimeZoneData.canonical_zone_list
    assert list |> Enum.member?("Europe/Copenhagen")
    assert !(list |> Enum.member?("Europe/Jersey"))
    assert !(list |> Enum.member?("Fantasy/Narnia"))
  end

  test "boolean functions that say whether a zone exists, is an alias, canonical" do
    assert TimeZoneData.zone_exists?("Europe/Copenhagen")
    assert TimeZoneData.zone_exists?("Europe/Jersey")
    assert !(TimeZoneData.zone_exists?("Fantasy/Narnia"))

    assert TimeZoneData.canonical_zone?("Europe/Copenhagen")
    assert !(TimeZoneData.canonical_zone?("Europe/Jersey"))
    assert !(TimeZoneData.canonical_zone?("Fantasy/Narnia"))

    assert !(TimeZoneData.zone_alias?("Europe/Copenhagen"))
    assert TimeZoneData.zone_alias?("Europe/Jersey")
    assert !(TimeZoneData.zone_alias?("Fantasy/Narnia"))
  end

  test "tzdata release version" do
    version =  TimeZoneData.tzdata_version
    assert String.length(version) == 5 # should be 5 chars long e.g. 2013a or 2014i
  end

  test "get periods for a certain zone and point in time" do
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{0,59,0}})
    periods = TimeZoneData.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 1
    # Around the time where the clocks are changed from summer to winter time,
    # the same wall time hour happens twice
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{1,20,0}})
    periods = TimeZoneData.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 2
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{3,59,0}})
    periods = TimeZoneData.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 1
  end

  test "get periods for a point in time where zone has to use :min and :max" do
    time = :calendar.datetime_to_gregorian_seconds({{2000,1,1},{1,20,0}})
    periods = TimeZoneData.periods_for_time "UTC", time, :wall
    assert periods|> length == 1
  end
end
