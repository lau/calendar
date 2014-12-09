defmodule FormatterTest do
  use ExUnit.Case, async: true
  alias Kalends.DateTime.Format
  doctest Format

  test "iso8601 formatting" do
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
    assert Format.iso8601(time) == "2014-09-26T17:10:20-03:00"
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Format.iso8601(time) == "2014-09-26T07:00:02+02:00"
    {:ok, time} = Kalends.DateTime.from_erl({{10, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Format.iso8601(time) == "0010-09-26T07:00:02+00:50"
  end

  test "iso8601 formatting with UTC time zone" do
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "Etc/UTC")
    assert Format.iso8601(time) == "2014-09-26T17:10:20Z"
    {:ok, time} = Kalends.DateTime.from_erl({{2014, 9, 26}, {7, 0, 2}}, "UTC")
    assert Format.iso8601(time) == "2014-09-26T07:00:02Z"
  end
end
