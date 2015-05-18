defmodule FormatterTest do
  use ExUnit.Case, async: true
  alias Calendar.DateTime
  alias Calendar.DateTime.Format
  doctest Format

  test "rfc3339 formatting" do
    {:ok, time} = Calendar.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
    assert Format.rfc3339(time) == "2014-09-26T17:10:20-03:00"
    {:ok, time} = Calendar.DateTime.from_erl({{2014, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Format.rfc3339(time) == "2014-09-26T07:00:02+02:00"
    {:ok, time} = Calendar.DateTime.from_erl({{10, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert Format.rfc3339(time) == "0010-09-26T07:00:02+00:50"
  end

  test "rfc3339 formatting with UTC time zone" do
    {:ok, time} = Calendar.DateTime.from_erl({{2014, 9, 26}, {17, 10, 20}}, "Etc/UTC")
    assert Format.rfc3339(time) == "2014-09-26T17:10:20Z"
    {:ok, time} = Calendar.DateTime.from_erl({{2014, 9, 26}, {7, 0, 2}}, "UTC")
    assert Format.rfc3339(time) == "2014-09-26T07:00:02Z"
  end
end
