defmodule FormatterTest do
  use ExUnit.Case, async: true
  alias Kalends.Formatter, as: Formatter
  doctest Kalends.Formatter

  test "from erl" do
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
    assert Formatter.iso8601(time) == "2014-09-26T17:10:20-3:00"
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Formatter.iso8601(time) == "2014-09-26T07:00:02+2:00"
    {:ok, time} = Kalends.DateTime.from_erl({{10, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Formatter.iso8601(time) == "0010-09-26T07:00:02+0:50"
  end

end
