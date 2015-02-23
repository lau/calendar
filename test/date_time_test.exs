defmodule DateTimeTest do
  use ExUnit.Case, async: true
  import Kalends.DateTime
  doctest Kalends.DateTime

  test "now" do
    assert Kalends.DateTime.now("America/Montevideo").year > 1900
    # the test below needs to be changed if there are changes on Iceland
    assert Kalends.DateTime.now("Atlantic/Reykjavik").abbr == "GMT"
  end

  test "to erl" do
    {{year,_,_},{_,_,_}} = Kalends.DateTime.to_erl(Kalends.DateTime.now("UTC"))
    assert year > 1900
  end

  test "from_erl invalid datetime" do
    result = from_erl({{2014, 99, 99}, {17, 10, 20}}, "UTC")
    assert result == {:error, :invalid_datetime}
  end

  test "from_erl non-existing timezone" do
    result = from_erl({{2014, 9, 26}, {17, 10, 20}}, "Non-existing timezone")
    assert result == {:error, :timezone_not_found}
  end

  test "non-existing wall time" do
    result = from_erl({{2014, 3, 30}, {2, 20, 02}}, "Europe/Copenhagen")
    assert result == {:error, :invalid_datetime_for_timezone}
  end

  test "shift_zone! works even for periods when wall clock is set back in fall because of DST" do
      result =  from_erl!({{1999,10,31},{0,29,10}}, "Etc/UTC") |> shift_zone!("Europe/Copenhagen") |> shift_zone!("Etc/UTC") |> shift_zone!("Europe/Copenhagen")
      assert result == %Kalends.DateTime{abbr: "CEST", day: 31, hour: 2, min: 29, month: 10, sec: 10, timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 3600, year: 1999}

      result2 = from_erl!({{1999,10,31},{1,29,10}}, "Etc/UTC") |> shift_zone!("Europe/Copenhagen") |> shift_zone!("Etc/UTC") |> shift_zone!("Europe/Copenhagen")
      assert result2 == %Kalends.DateTime{abbr: "CET", day: 31, hour: 2, min: 29, month: 10, sec: 10, timezone: "Europe/Copenhagen", utc_off: 3600, std_off: 0, year: 1999}
  end
end
