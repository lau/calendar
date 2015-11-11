defmodule Calendar.IntervalTest do
  use ExUnit.Case, async: true
  use Calendar

  doctest Calendar.Interval

  setup do
    interval = %Interval{
      from: DateTime.from_erl!({{2015, 1, 1}, {12, 0, 0}}, "Europe/Brussels", 0),
      to: DateTime.from_erl!({{2015, 1, 2}, {12, 0, 0}}, "Europe/Brussels", 0)
    }
    {:ok, interval: interval}
  end

  test "includes? returns true when the interval contains the datetime", %{interval: interval} do
    assert Interval.includes?(
      interval, DateTime.from_erl!({{2015, 1, 1}, {13, 0, 0}}, "Europe/Brussels", 0)) == true
  end

  test "includes? returns false the datetime is later", %{interval: interval} do
    assert Interval.includes?(
      interval, DateTime.from_erl!({{2015, 1, 2}, {13, 0, 0}}, "Europe/Brussels", 0)) == false
  end

  test "includes? returns false the datetime is earlier", %{interval: interval} do
    assert Interval.includes?(
      interval, DateTime.from_erl!({{2015, 1, 1}, {11, 0, 0}}, "Europe/Brussels", 0)) == false
  end
end
