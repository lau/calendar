defmodule TzUtilTest do
  use ExUnit.Case, async: true
  alias Kalends.TzUtil, as: TzUtil
  import Kalends.TzUtil
  doctest Kalends.TzUtil

  test "get last weekday of month" do
    # last thursday of Aug 2014 should be on the 28th
    assert TzUtil.last_weekday_of_month(2014, 8, 4) == 28
    # last sunday of Aug 2014 should be on the 31st
    assert TzUtil.last_weekday_of_month(2014, 8, 7) == 31
    # should also accept string with english abbrevations of weekdays
    assert TzUtil.last_weekday_of_month(2014, 8, "sun") == 31
    assert TzUtil.last_weekday_of_month(2014, 8, "thu") == 28
  end

  test "transform 'until' date-time" do
    assert TzUtil.transform_until_datetime("1918 Nov 11 11:00u") == {{{1918,11,11}, {11,0,0}}, :utc}
    assert TzUtil.transform_until_datetime("1940 May 20  2:00s") == {{{1940,5,20}, {2,0,0}}, :standard}
    assert TzUtil.transform_until_datetime("1944 Sep  3") == {{{1944,9,3}, {0,0,0}}, :wall}
    assert TzUtil.transform_until_datetime("1977") == {{{1977,1,1}, {0,0,0}}, :wall}
    assert TzUtil.transform_until_datetime("1992 Sep lastSat 23:00") == {{{1992,9,26}, {23,0,0}}, :wall}
    assert TzUtil.transform_until_datetime("1992 Sep lastSat") == {{{1992,9,26}, {0,0,0}}, :wall}
  end

  test "month_number_for_month_name" do
    assert TzUtil.month_number_for_month_name("Mar") == 3
    assert TzUtil.month_number_for_month_name("mar") == 3
    assert TzUtil.month_number_for_month_name("3") == 3
  end

  test "rules that apply for a certain year" do
    {:ok, rules} = Kalends.TzData.rules("Denmark")
    assert TzUtil.rules_for_year(rules, 1800) == []
    assert TzUtil.rules_for_year(rules, 1915) |> length == 0
    assert TzUtil.rules_for_year(rules, 1916) |> length == 2
    assert TzUtil.rules_for_year(rules, 1917) |> length == 0
  end

  test "Time for rule applying" do
    rule = %{at: {{1, 0, 0}, :utc}, from: 1979, in: 9, letter: "-", name: "EU", on: "lastSun", record_type: :rule, save: 0, to: 1995, type: "-"}
    assert TzUtil.time_for_rule(rule, 1990) == {{{1990, 9, 30}, {1,0,0}}, :utc}

    rule = %{at: {{1, 0, 0}, :wall}, from: 1917, in: 10, letter: "-", name: "Iceland", on: "21", record_type: :rule, save: 0, to: :only, type: "-"}
    assert TzUtil.time_for_rule(rule, 1917) == {{{1917, 10, 21}, {1,0,0}}, :wall}
  end
end
