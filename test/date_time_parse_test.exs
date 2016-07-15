defmodule DateTimeParseTest do
  use ExUnit.Case, async: true
  alias Calendar.DateTime.Parse
  import Parse
  doctest Parse

  test "microsecond precision is capped at 6" do
    assert(unix!("1000000000.123456789").microsecond == {123457, 6})
  end
end
