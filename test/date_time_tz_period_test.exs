defmodule DateTimeTzPeriodTest do
  use ExUnit.Case, async: true
  alias Calendar.DateTime
  import Calendar.DateTime.TzPeriod
  doctest Calendar.DateTime.TzPeriod
end
