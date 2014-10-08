defmodule TzParserTest do
  use ExUnit.Case, async: true
  alias Kalends.TzParsing.TzParser, as: TzParser

  test "process rule" do
    zone_text = "Rule	EU	1977	1980	-	Apr	Sun>=1	 1:00u	1:00	S\n"
    processed = TzParser.process_rule(zone_text)
    assert processed == %{at: {{1,0,0}, :utc}, from: 1977, in: 4, letter: "S", name: "EU", on: "Sun>=1", record_type: :rule, save: 3600,
             to: 1980, type: "-"}
  end

  test "process link" do
    text = "Link	Europe/London	Europe/Jersey\n"
    processed = TzParser.process_link(text)
    assert processed == %{record_type: :link, from: "Europe/London", to: "Europe/Jersey"}
  end

  test "process zone" do
    zone_text = """
                Zone	Europe/London	-0:01:15 -	LMT	1847 Dec  1 0:00s
                			 0:00	GB-Eire	%s	1968 Oct 27
                			 1:00	-	BST	1971 Oct 31 2:00u
                			 0:00	GB-Eire	%s	1996
                			 0:00	EU	GMT/BST
                """
    zone_list = String.split(zone_text, "\n")
    processed = TzParser.process_zone(zone_list)
    assert hd(processed) == %{name: "Europe/London", record_type: :zone,
             zone_lines: [%{format: "LMT", gmtoff: -75, rules: nil, until: {{{1847, 12, 1}, {0, 0, 0}}, :standard}},
              %{format: "%s", gmtoff: 0, rules: {:named_rules, "GB-Eire"}, until: {{{1968, 10, 27}, {0, 0, 0}}, :wall}},
              %{format: "BST", gmtoff: 3600, rules: nil, until: {{{1971, 10, 31}, {2, 0, 0}}, :utc}},
              %{format: "%s", gmtoff: 0, rules: {:named_rules, "GB-Eire"}, until: {{{1996, 1, 1}, {0, 0, 0}}, :wall}},
              %{format: "GMT/BST", gmtoff: 0, rules: {:named_rules, "EU"}}]}
  end

  test "process zone - map lines - continuation with until" do
		line = "1:00	-	BST	1971 Oct 31 2:00u\n"
    result = TzParser.zone_mapped(line)
    assert elem(result,0) == :continuation_with_until
  end

  test "remove a comment from the end of a line" do
    line = "6:30	-	MMT		   # Myanmar Time\n"
    assert TzParser.strip_comment(line) == "6:30	-	MMT\n"
  end
end
