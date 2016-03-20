defmodule Calendar.DateTime.IntervalTest do
  use ExUnit.Case, async: true

  doctest Calendar.DateTime.Interval

  setup do
    interval = %Calendar.DateTime.Interval{
      from: Calendar.DateTime.from_erl!({{2015, 1, 1}, {12, 0, 0}}, "Europe/Brussels", 0),
      to: Calendar.DateTime.from_erl!({{2015, 1, 2}, {12, 0, 0}}, "Europe/Brussels", 0)
    }
    {:ok, interval: interval}
  end

  test "includes? returns true when the interval contains the datetime", %{interval: interval} do
    assert Calendar.DateTime.Interval.includes?(
      interval, Calendar.DateTime.from_erl!({{2015, 1, 1}, {13, 0, 0}}, "Europe/Brussels", 0)) == true
  end

  test "includes? returns true when the interval start is equal to the the datetime", %{interval: interval} do
    assert Calendar.DateTime.Interval.includes?(
      interval, Calendar.DateTime.from_erl!({{2015, 1, 1}, {12, 0, 0}}, "Europe/Brussels", 0)) == true
  end

  test "includes? returns true when the interval end is equal to the the datetime", %{interval: interval} do
    assert Calendar.DateTime.Interval.includes?(
      interval, Calendar.DateTime.from_erl!({{2015, 1, 2}, {12, 0, 0}}, "Europe/Brussels", 0)) == true
  end

  test "includes? returns false the datetime is later", %{interval: interval} do
    assert Calendar.DateTime.Interval.includes?(
      interval, Calendar.DateTime.from_erl!({{2015, 1, 2}, {13, 0, 0}}, "Europe/Brussels", 0)) == false
  end

  test "includes? returns false the datetime is earlier", %{interval: interval} do
    assert Calendar.DateTime.Interval.includes?(
      interval, Calendar.DateTime.from_erl!({{2015, 1, 1}, {11, 0, 0}}, "Europe/Brussels", 0)) == false
  end
end
