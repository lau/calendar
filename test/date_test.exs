defmodule SomethingThatContainsDate do
  defstruct []
end

defimpl Calendar.ContainsDate, for: SomethingThatContainsDate do
  def date_struct(_), do: %Calendar.Date{year: 2015, month: 1, day: 1}
end

defmodule DateTest do
  use ExUnit.Case, async: true
  import Calendar.Date
  alias Calendar.NaiveDateTime
  doctest Calendar.Date

  test "to_erl works for anything that contains a date" do
    assert to_erl(%SomethingThatContainsDate{}) == {2015, 1, 1}
  end
end
