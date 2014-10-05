defmodule Kalends.TzParser do
  @moduledoc false
  import Kalends.TzUtil
  def read_file(file_name, dir_prepend \\ "tzdata") do
    File.stream!("#{dir_prepend}/#{file_name}")
    |> process_file
  end

  def process_file(file_stream) do
    file_stream
    |> filter_comment_lines
    |> filter_empty_lines
    |> Enum.to_list
    |> Enum.map(fn string -> strip_comment(string) end) # Strip comments at line end. Like this comment.
    |> process_tz_list
  end

  def strip_comment(line), do: Regex.replace(~r/[\s]*#.+/, line, "")

  def filter_comment_lines(input) do
    Stream.filter(input, fn x -> !Regex.match?(~r/^[\s]*#/, x) end)
  end

  def filter_empty_lines(input) do
    Stream.filter(input, fn x -> !Regex.match?(~r/^\n$/, x) end)
  end

  def process_tz_list([]), do: []
  def process_tz_list([ head | tail ]) do
    split = String.split(head, ~r{\s})
    case hd(split) do
      "Rule" -> [process_rule(head)|process_tz_list(tail)]
      "Link" -> [process_link(head)|process_tz_list(tail)]
      "Zone" -> process_zone([head|tail])
      ______ -> [head|process_tz_list(tail)] # pass through
    end
  end

  def process_rule(line) do
    rule_regex = ~r/Rule[\s]+(?<name>[^\s]+)[\s]+(?<from>[^\s]+)[\s]+(?<to>[^\s]+)[\s]+(?<type>[^\s]+)[\s]+(?<in>[^\s]+)[\s]+(?<on>[^\s]+)[\s]+(?<at>[^\s]+)[\s]+(?<save>[^\s]+)[\s]+(?<letter>[^\n]+)/
    captured = Regex.named_captures(rule_regex, line)
    captured = %{name: captured["name"],
                 from: captured["from"] |> to_int,
                 to: captured["to"] |> process_rule_to,
                 type: captured["type"], # we don't use this column for anything
                 in: captured["in"] |> month_number_for_month_name,
                 on: captured["on"],
                 at: captured["at"] |> transform_rule_at,
                 save: captured["save"] |> string_amount_to_secs,
                 letter: captured["letter"]}
    Map.merge(captured, %{record_type: :rule})
  end

  # process "to" value of rule
  defp process_rule_to("only"), do: :only
  defp process_rule_to("max"), do: :max
  defp process_rule_to(val), do: val |> to_int

  def process_link(line) do
    link_regex = ~r/Link[\s]+(?<from>[^\s]+)[\s]+(?<to>[^\s]+)/
    captured = Regex.named_captures(link_regex, line)
    %{record_type: :link, from: captured["from"], to: captured["to"]}
  end

  def process_zone(:head_no_until, captured, [head|tail]) do
    name = captured["name"]
    captured = captured_zone_map_clean_up(captured)
    [%{record_type: :zone, name: name, zone_lines: [captured]}|process_tz_list([head|tail])]
  end

  def process_zone(:head_no_until, captured, []) do
    name = captured["name"]
    captured = captured_zone_map_clean_up(captured)
    [%{record_type: :zone, name: name, zone_lines: [captured]}]
  end

  def process_zone(:head_with_until, captured, [head|tail]) do
    name = captured["name"]
    captured = captured_zone_map_clean_up(captured)
    {line_type, new_capture} = zone_mapped(head)
    process_zone(line_type, new_capture, name, [captured], tail)
  end

  def process_zone(:continuation_with_until, captured, zone_name, zone_lines, [head|tail]) do
    captured = captured_zone_map_clean_up(captured)
    zone_lines = zone_lines ++ [captured]
    {line_type, new_capture} = zone_mapped(head)
    process_zone(line_type, new_capture, zone_name, zone_lines, tail)
  end

  def process_zone(:continuation_no_until, captured, zone_name, zone_lines, [head|tail]) do
    captured = captured_zone_map_clean_up(captured)
    zone_lines = zone_lines ++ [captured]
    [%{record_type: :zone, name: zone_name, zone_lines: zone_lines}|process_tz_list([head|tail])]
  end

  def process_zone(:continuation_no_until, captured, zone_name, zone_lines, []) do
    captured = captured_zone_map_clean_up(captured)
    zone_lines = zone_lines ++ [captured]
    [%{record_type: :zone, name: zone_name, zone_lines: zone_lines}]
  end

  def process_zone([head|tail]) do
    {line_type, captured} = zone_mapped(head)
    process_zone(line_type, captured, tail)
  end

  def zone_mapped(line) do
    # I use the term "head" in this context as the first line of a zone
    # definition. So it will start with "Zone"
    zone_line_regex = [
      {:head_with_until, ~r/Zone[\s]+(?<name>[^\s]+)[\s]+(?<gmtoff>[^\s]+)[\s]+(?<rules>[^\s]+)[\s]+(?<format>[^\s]+)[\s]+(?<until>[^\n]+)/},
      {:head_no_until, ~r/Zone[\s]+(?<name>[^\s]+)[\s]+(?<gmtoff>[^\s]+)[\s]+(?<rules>[^\s]+)[\s]+(?<format>[^\s]+)/},
      {:continuation_with_until, ~r/[\s]+(?<gmtoff>[^\s]+)[\s]+(?<rules>[^\s]+)[\s]+(?<format>[^\s]+)[\s]+(?<until>[^\n]+)/},
      {:continuation_no_until, ~r/[\s]+(?<gmtoff>[^\s]+)[\s]+(?<rules>[^\s]+)[\s]+(?<format>[^\s]+)/},
    ]
    zone_mapped(line, zone_line_regex)
  end

  defp zone_mapped(_line, []), do: {:error, :no_regex_matched}
  defp zone_mapped(line,[regex_head|tail]) do
    regex_name = elem(regex_head,0)
    regex = elem(regex_head,1)
    if Regex.match?(regex, line) do
      captured = Regex.named_captures(regex, line)
      {regex_name, captured}
    else
      zone_mapped(line, tail)
    end
  end

  # if format in zone line is "-" change it to nil
  defp transform_zone_line_rules("-"), do: nil
  defp transform_zone_line_rules("0"), do: nil
  defp transform_zone_line_rules(string) do
    transform_zone_line_rules(string, Regex.match?(~r/\d/, string))
  end
  # If the regexp does not contain a number, we assume a named rule
  defp transform_zone_line_rules(string, false), do: {:named_rules, string}
  defp transform_zone_line_rules(string, true) do
    {:amount, string |> string_amount_to_secs}
  end

  # Converts keys to atoms. Discards "name"
  defp captured_zone_map_clean_up(captured) do
    until = transform_until_datetime(captured["until"])
    map = %{gmtoff: Kalends.TzUtil.string_amount_to_secs(captured["gmtoff"]),
    rules: transform_zone_line_rules(captured["rules"]),
    format: captured["format"],
    until: until}
    # remove until key if it is nil
    if (map[:until]==nil) do map = Map.delete(map,:until) end
    map
  end
end
