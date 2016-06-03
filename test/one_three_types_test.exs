if Version.match?(System.version, ">= 1.3.0 or ~> 1.3.0-dev") do
  defmodule OneThreeTypesTest do
    use ExUnit.Case, async: true

    test "Date format" do
      assert ~D[2016-02-01] |> Calendar.Date.Format.iso8601 == "2016-02-01"
    end

    test "Time format" do
      assert ~T[23:04:05] |> Calendar.Time.Format.iso8601 == "23:04:05"
    end

    test "Time usec" do
      assert ~T[23:04:05.12345] |> Calendar.Time.to_micro_erl == {23, 4, 5, 123450}
    end

    test "NaiveDateTime microerl" do
      assert ~N[2016-02-01 23:04:05.12345] |> Calendar.NaiveDateTime.to_micro_erl == {{2016, 2, 1}, {23, 4, 5, 123450}}
    end

    test "DateTime microerl" do
      assert %DateTime{calendar: Calendar.ISO, day: 2, hour: 20, microsecond: {123450, 6}, minute: 10, month: 1, second: 1, std_offset: 0, time_zone: "Etc/UTC",
 utc_offset: 0, year: 2016, zone_abbr: "UTC"} |> Calendar.DateTime.to_micro_erl == {{2016, 1, 2}, {20, 10, 1, 123450}}
    end

    test "DateTime rfc3339" do
      assert %DateTime{calendar: Calendar.ISO, day: 2, hour: 20, microsecond: {123450, 6}, minute: 10, month: 1, second: 1, std_offset: 0, time_zone: "Etc/UTC",
 utc_offset: 0, year: 2016, zone_abbr: "UTC"} |> Calendar.DateTime.Format.rfc3339 =="2016-01-02T20:10:01.123450Z"
    end
  end
end
