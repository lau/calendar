defmodule SomethingThatContainsTime do
  defstruct []
end

defimpl Calendar.ContainsTime, for: SomethingThatContainsTime do
  def time_struct(_), do: %Time{hour: 1, minute: 1, second: 1, microsecond: 1}
end

defmodule TimeTest do
  use ExUnit.Case, async: true
  import Calendar.Time
  doctest Calendar.Time

  test "to_erl works for anything that contains a time" do
    assert to_erl(%SomethingThatContainsTime{}) == {1, 1, 1}
  end
end
