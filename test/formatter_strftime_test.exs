defmodule FormatterStrfTimeTest do
  use ExUnit.Case, async: true
  alias Calendar.Strftime
  alias Calendar.DateTime
  alias Calendar.NaiveDateTime
  alias Calendar.Date
  alias Calendar.Time
  import Strftime
  doctest Strftime

  test "strftime" do
    dt = Calendar.DateTime.from_erl!({{2014, 11, 3}, {1, 41, 2}}, "UTC", 123456)
    dt_sunday = Calendar.DateTime.from_erl!({{2014, 11, 2}, {1, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%a") == "Mon"
    assert Strftime.strftime!(dt, "%A") == "Monday"
    assert Strftime.strftime!(dt, "%b") == "Nov"
    assert Strftime.strftime!(dt, "%h") == "Nov"
    assert Strftime.strftime!(dt, "%B") == "November"
    assert Strftime.strftime!(dt, "%d") == "03"
    assert Strftime.strftime!(dt, "%e") == " 3"
    assert Strftime.strftime!(dt, "%f") == "123456"
    assert Strftime.strftime!(dt, "%u") == "1"
    assert Strftime.strftime!(dt, "%w") == "1"
    assert Strftime.strftime!(dt_sunday, "%u") == "7"
    assert Strftime.strftime!(dt_sunday, "%w") == "0"
    assert Strftime.strftime!(dt, "%V") == "45"
    assert Strftime.strftime!(dt, "%G") == "2014"
    assert Strftime.strftime!(dt, "%g") == "14"
    assert Strftime.strftime!(dt, "%C") == "20"
    assert Strftime.strftime!(dt, "%k") == " 1"
    assert Strftime.strftime!(dt, "%I") == "01"
    assert Strftime.strftime!(dt, "%l") == " 1"
    assert Strftime.strftime!(dt, "%P") == "am"
    assert Strftime.strftime!(dt, "%p") == "AM"
    assert Strftime.strftime!(dt, "%r") == "01:41:02 AM"
    assert Strftime.strftime!(dt, "%R") == "01:41"
    assert Strftime.strftime!(dt, "%T") == "01:41:02"
    assert Strftime.strftime!(dt, "%F") == "2014-11-03"
    assert Strftime.strftime!(dt, "%Z") == "UTC"
  end

  test "strftime am pm" do
    dt = Calendar.DateTime.from_erl!({{2014, 12, 31}, {21, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%l %P") == " 9 pm"
    assert Strftime.strftime!(dt, "%I %p") == "09 PM"
    dt = Calendar.DateTime.from_erl!({{2014, 12, 31}, {12, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%l %P") == "12 pm"
    assert Strftime.strftime!(dt, "%I %p") == "12 PM"
    dt = Calendar.DateTime.from_erl!({{2014, 12, 31}, {0, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%l %P") == "12 am"
    assert Strftime.strftime!(dt, "%I %p") == "12 AM"
    dt = Calendar.DateTime.from_erl!({{2014, 12, 31}, {9, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%l %P") == " 9 am"
    assert Strftime.strftime!(dt, "%I %p") == "09 AM"
  end

  test "strftime day number in year" do
    dt = Calendar.DateTime.from_erl!({{2014, 12, 31}, {21, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%j") == "365"
    dt = Calendar.DateTime.from_erl!({{2014, 1, 1}, {21, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%j") == "001"
    # Leap year
    dt = Calendar.DateTime.from_erl!({{2012, 12, 31}, {21, 41, 2}}, "UTC")
    assert Strftime.strftime!(dt, "%j") == "366"
  end
end
