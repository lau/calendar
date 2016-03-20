defmodule Calendar.NaiveDateTime.IntervalTest do
  use ExUnit.Case, async: true

  doctest Calendar.NaiveDateTime.Interval

  setup do
    interval = %Calendar.NaiveDateTime.Interval{
      from: Calendar.NaiveDateTime.from_erl!({{2015, 1, 1}, {12, 0, 0}}),
      to: Calendar.NaiveDateTime.from_erl!({{2015, 1, 2}, {12, 0, 0}})
    }
    {:ok, interval: interval}
  end
end
