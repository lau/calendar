defmodule TimeZonePeriodsTest do
  use ExUnit.Case, async: true
  alias Kalends.TimeZonePeriods, as: TimeZonePeriods

  test "get periods for a certain zone and point in time" do
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{0,59,0}})
    periods = TimeZonePeriods.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 1
    # Around the time where the clocks are changed from summer to winter time,
    # the same wall time hour happens twice
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{1,20,0}})
    periods = TimeZonePeriods.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 2
    time = :calendar.datetime_to_gregorian_seconds({{2006,10,29},{3,59,0}})
    periods = TimeZonePeriods.periods_for_time "America/Chicago", time, :wall
    assert periods|> length == 1
  end

  test "get periods for a point in time where zone has to use :min and :max" do
    time = :calendar.datetime_to_gregorian_seconds({{2000,1,1},{1,20,0}})
    periods = TimeZonePeriods.periods_for_time "UTC", time, :wall
    assert periods|> length == 1
  end
end
