defmodule DateTimeTest do
  use ExUnit.Case, async: true
  import Kalends.DateTime
  alias Kalends.DateTime, as: DateTime
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

  test "from erl" do
    result = DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}})
    assert result == {:ok, %Kalends.DateTime{date: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014, timezone: nil, abbr: nil} }
  end

  test "from_erl invalid datetime" do
    result = from_erl({{2014, 99, 99}, {17, 10, 20}})
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
end
