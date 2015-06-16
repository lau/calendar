defmodule NaiveDateTimeParseTest do
  use ExUnit.Case, async: true
  alias Calendar.NaiveDateTime.Parse
  import Parse
  doctest Parse
end
