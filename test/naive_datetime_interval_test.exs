defmodule Calendar.NaiveDateTime.IntervalTest do
  use ExUnit.Case, async: true
  use Calendar

  doctest Calendar.NaiveDateTime.Interval

  setup do
    interval = %NaiveDateTime.Interval{
      from: NaiveDateTime.from_erl!({{2015, 1, 1}, {12, 0, 0}}),
      to: NaiveDateTime.from_erl!({{2015, 1, 2}, {12, 0, 0}})
    }
    {:ok, interval: interval}
  end
end
