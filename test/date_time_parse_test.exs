defmodule DateTimeParseTest do
  use ExUnit.Case, async: true
  alias Calendar.DateTime.Parse
  import Parse
  doctest Parse

  test "microsecond precision is capped at 6" do
    assert(unix!("1000000000.123456789").microsecond == {123456, 6})
  end

  test "microsecond part is truncated, not rounded" do
    assert(unix!("1000000000.999999999").microsecond == {999999, 6})
  end

  test "parsing floats always sets microsecond precision to 6" do
    assert(unix!(1.1).microsecond == {100_000, 6})
    assert(unix!(1.123456789).microsecond == {123_457, 6})
    assert(unix!(1.0).microsecond == {0, 6})
  end
end
