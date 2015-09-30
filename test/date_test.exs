defmodule DateTest do
  use ExUnit.Case, async: true
  import Calendar.Date
  alias Calendar.NaiveDateTime
  doctest Calendar.Date
end
