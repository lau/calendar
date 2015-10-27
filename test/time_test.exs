defmodule SomethingThatContainsTime do
  defstruct []
end

defimpl Calendar.ContainsTime, for: SomethingThatContainsTime do
  def time_struct(_), do: %Calendar.Time{hour: 1, min: 1, sec: 1, usec: 1}
end

defmodule TimeTest do
  use ExUnit.Case, async: true
  alias Calendar.Time
  import Calendar.Time
  doctest Calendar.Time

  test "to_erl works for anything that contains a time" do
    assert to_erl(%SomethingThatContainsTime{}) == {1, 1, 1}
  end
end
