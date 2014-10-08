defmodule TzDataTest do
  use ExUnit.Case, async: true
  alias Kalends.TzParsing.TzData, as: TzData

  test "Existing rule" do
    result = TzData.rules("Uruguay")
    assert elem(result, 0) == :ok
    assert hd(elem(result, 1))[:name] == "Uruguay"
  end

  test "Existing zone" do
    result = TzData.zone("Europe/Copenhagen")
    assert elem(result, 0) == :ok
    assert elem(result, 1)[:name] == "Europe/Copenhagen"
  end

  test "When trying to get a zone by linked name, return canonical zone" do
    result = TzData.zone("Iceland")
    assert elem(result, 0) == :ok
    assert elem(result, 1)[:name] == "Atlantic/Reykjavik"
  end

  test "trying to get non existing zone should result in error" do
    assert TzData.zone("Foo/Bar") == {:error, :not_found}
  end

  test "trying to get non existing rules should result in error" do
    assert TzData.rules("Narnia") == {:error, :not_found}
  end

  test "Should provide list of zone names and link names" do
    # London is cononical zone. Jersey is a link
    assert TzData.zone_list |> Enum.member? "Europe/London"
    assert TzData.zone_list |> Enum.member?("Europe/Jersey") != true
    assert TzData.link_list |> Enum.member?("Europe/London") != true
    assert TzData.link_list |> Enum.member? "Europe/Jersey"
    assert TzData.zone_and_link_list |> Enum.member? "Europe/London"
    assert TzData.zone_and_link_list |> Enum.member? "Europe/Jersey"
  end
end
