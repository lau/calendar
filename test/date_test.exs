defmodule SomethingThatContainsDate do
  defstruct []
end

defimpl Calendar.ContainsDate, for: SomethingThatContainsDate do
  def date_struct(_), do: %Calendar.Date{year: 2015, month: 1, day: 1}
end

defmodule DateTest do
  use ExUnit.Case, async: true
  import Calendar.Date
  doctest Calendar.Date

  test "to_erl works for anything that contains a date" do
    assert to_erl(%SomethingThatContainsDate{}) == {2015, 1, 1}
  end

  test "Using a tuple as an argument to a function that expects an argument implenting Calendar.ContainsDate" do
    assert to_erl({2015, 1, 1}) == {2015, 1, 1}
  end

  test "A 3 element tuple where the first element is less than 24, should raise in order to avoid ambiguity with a time tuple. E.g. {23, 10, 10} could be either 23:10:10 or October 10th in the year 23 A.D." do
    assert_raise RuntimeError, fn ->
      to_erl({23, 10, 10})
    end
  end
end
