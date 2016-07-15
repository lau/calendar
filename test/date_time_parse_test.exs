defmodule DateTimeParseTest do
  use ExUnit.Case, async: true
  alias Calendar.DateTime.Parse
  import Parse
  doctest Parse

  test "microsecond precision is capped at 6" do
    assert(unix!("1000000000.987654321").microsecond == {987654, 6})
  end
end
