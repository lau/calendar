defmodule Kalends.TzUtil do
  @moduledoc false
  @doc """
    Take strings of amounts and convert them to ints of seconds.
    For instance useful for strings from TZ gmt offsets.

    iex> string_amount_to_secs("0")
    0
    iex> string_amount_to_secs("10")
    36000
    iex> string_amount_to_secs("1:00")
    3600
    iex> string_amount_to_secs("-0:01:15")
    -75
    iex> string_amount_to_secs("-2:00")
    -7200
    iex> string_amount_to_secs("-1:30")
    -5400
    iex> string_amount_to_secs("0:50:20")
    3020
  """
  def string_amount_to_secs("0"), do: 0
  def string_amount_to_secs(string) do
    string
    |> String.strip
    |> String.split(":")
    |> _string_amount_to_secs
  end
  # If there is only one element, add 0 minutes and send to "normal" 2 parts
  # function
  defp _string_amount_to_secs(list) when length(list) == 1 do
    _string_amount_to_secs([hd(list), "00"])
  end
  # If there are 3 parts, the last one is seconds. We calculate the seconds
  # and send them to the "normal" function for 2 parts
  defp _string_amount_to_secs(list) when length(list) == 3 do
    secs_string = hd(Enum.reverse list)
    {secs, ""} = Integer.parse(secs_string)
    # remove seconds part from list
    list = List.delete_at(list, 2)
    _string_amount_to_secs(list, secs)
  end
  defp _string_amount_to_secs(list, secs\\0) when length(list) == 2 do
    {hours, ""} = Integer.parse(hd(list))
    {mins, ""} = Integer.parse(hd(Enum.reverse(list)))
    # if hours are negative, use the absolute value in this calculation
    result = abs(hours)*3600+mins*60+secs
    # if hours are negative, the whole result should be negative
    if Regex.match?(~r/-/, hd(list)), do: result = -1*result
    result
  end

  @doc """
  Provide a certain day number (eg. 1 for monday, 2 for tuesday)
  or downcase 3 letter abbreviation eg. "mon" for monday
  and a year and month.
  Get the last day of that type of the specified month.
  Eg 2014, 8, 5 for the last friday of August 2014. Will return 29

    iex> last_weekday_of_month(2014, 8, 5)
    29
  """
  def last_weekday_of_month(year, month, weekday) do
    weekday = weekday_string_to_number!(weekday)
    days_in_month = day_count_for_month(year, month)
    day_list = Enum.to_list days_in_month..1
    first_matching_weekday_in_month(year, month, weekday, day_list)
  end

  def first_weekday_of_month_at_least(year, month, weekday, minimum_date) do
    weekday = weekday_string_to_number!(weekday)
    days_in_month = day_count_for_month(year, month)
    day_list = Enum.to_list minimum_date..days_in_month
    first_matching_weekday_in_month(year, month, weekday, day_list)
  end

  defp first_matching_weekday_in_month(year, month, weekday, [head|tail]) do
    if weekday == day_of_the_week(year, month, head) do
      head
    else
      first_matching_weekday_in_month(year, month, weekday, tail)
    end
  end

  def day_count_for_month(year, month), do: :calendar.last_day_of_the_month(year, month)

  def day_of_the_week(year, month, day), do: :calendar.day_of_the_week(year, month, day)

  def weekday_string_to_number!("mon"), do: 1
  def weekday_string_to_number!("tue"), do: 2
  def weekday_string_to_number!("wed"), do: 3
  def weekday_string_to_number!("thu"), do: 4
  def weekday_string_to_number!("fri"), do: 5
  def weekday_string_to_number!("sat"), do: 6
  def weekday_string_to_number!("sun"), do: 7
  # pass through if not matched!
  def weekday_string_to_number!(parm), do: parm

  def month_number_for_month_name(string) do
    string
    |> String.downcase
    |> cap_month_number_for_month_name
  end
  defp cap_month_number_for_month_name("jan"), do: 1
  defp cap_month_number_for_month_name("feb"), do: 2
  defp cap_month_number_for_month_name("mar"), do: 3
  defp cap_month_number_for_month_name("apr"), do: 4
  defp cap_month_number_for_month_name("may"), do: 5
  defp cap_month_number_for_month_name("jun"), do: 6
  defp cap_month_number_for_month_name("jul"), do: 7
  defp cap_month_number_for_month_name("aug"), do: 8
  defp cap_month_number_for_month_name("sep"), do: 9
  defp cap_month_number_for_month_name("oct"), do: 10
  defp cap_month_number_for_month_name("nov"), do: 11
  defp cap_month_number_for_month_name("dec"), do: 12
  defp cap_month_number_for_month_name(string), do: to_int(string)

  @doc """
  Takes a year and month int and a day that is a string.
  The day string can be either a number e.g. "5" or TZ data style definition
  such as "lastSun" or sun>=8
  """
  def tz_day_to_int(year, month, day) do
    last_regex = ~r/last(?<day_name>[^\s]+)/
    at_least_regex = ~r/(?<day_name>[^\s]+)\>\=(?<at_least>\d+)/
    cond do
      Regex.match?(last_regex, day) ->
        weekdayHash = Regex.named_captures last_regex, day
        day_name = String.downcase weekdayHash["day_name"]
        last_weekday_of_month(year, month, day_name)
      Regex.match?(at_least_regex, day) ->
        weekdayHash = Regex.named_captures at_least_regex, day
        day_name = String.downcase weekdayHash["day_name"]
        minimum_date = to_int weekdayHash["at_least"]
        first_weekday_of_month_at_least(year, month, day_name, minimum_date)
      true ->
        to_int day
    end
  end
  def to_int(string) do elem(Integer.parse(string),0) end
  def transform_until_datetime(nil), do: nil
  def transform_until_datetime(input_date_string) do
    regex_year_only = ~r/(?<year>\d+)/
    regex_year_month = ~r/(?<year>\d+)[\s]+(?<month>[^\s]+)/
    regex_year_date = ~r/(?<year>\d+)[\s]+(?<month>[^\s]+)[\s]+(?<date>[^\s]*)/
    regex_year_date_time = ~r/(?<year>\d+)[\s]+(?<month>[^\s]+)[\s]+(?<date>[^\s]+)[\s]+(?<hour>[^\s]*):(?<min>[^\s]*)/
    cond do
      Regex.match?(regex_year_date_time, input_date_string) ->
        captured = Regex.named_captures(regex_year_date_time, input_date_string)
        transform_until_datetime(:year_date_time, captured)
      Regex.match?(regex_year_date, input_date_string) ->
        captured = Regex.named_captures(regex_year_date, input_date_string)
        transform_until_datetime(:year_date, captured)
      Regex.match?(regex_year_month, input_date_string) ->
        captured = Regex.named_captures(regex_year_month, input_date_string)
        transform_until_datetime(:year_month, captured)
      Regex.match?(regex_year_only, input_date_string) ->
        captured = Regex.named_captures(regex_year_only, input_date_string)
        transform_until_datetime(:year_only, captured)
      true ->
        raise "none matched"
    end
  end

  def transform_until_datetime(:year_date_time, map) do
    year = to_int(map["year"])
    month_number = month_number_for_month_name(map["month"])
    date = tz_day_to_int(year, month_number, map["date"])

    {{{year, month_number, date},
      {to_int(map["hour"]),
       to_int(map["min"]),00}}, time_modifier(map["min"])}
  end

  def transform_until_datetime(:year_date, map) do
    year = to_int(map["year"])
    month_number = month_number_for_month_name(map["month"])
    date = tz_day_to_int(year, month_number, map["date"])
    {{{year, month_number, date},{0,0,0}}, :wall}
  end

  def transform_until_datetime(:year_month, map) do
    year = to_int(map["year"])
    month_number = month_number_for_month_name(map["month"])
    {{{year, month_number, 1},{0,0,0}}, :wall}
  end

  def transform_until_datetime(:year_only, map) do
    {{{to_int(map["year"]),1,1},{0,0,0}}, :wall}
  end

  @doc """
  Given a string of a Rule "AT" column return a tupple of a erlang style
  time tuple and a modifier that can be either :wall, :standard or :utc

  ## Examples
      iex> transform_rule_at("2:20u")
      {{2,20,0}, :utc}
      iex> transform_rule_at("2:00s")
      {{2,0,0}, :standard}
      iex> transform_rule_at("2:00")
      {{2,0,0}, :wall}
      iex> transform_rule_at("0")
      {{0,0,0}, :wall}
  """
  def transform_rule_at("0"), do: transform_rule_at "0:00"
  def transform_rule_at(string) do
    modifier = string |> time_modifier
    map = Regex.named_captures(~r/(?<hours>[0-9]{1,2})[\:\.](?<minutes>[0-9]{1,2})/, string)
    {{map["hours"]|>to_int, map["minutes"]|>to_int, 0}, modifier}
  end

  @doc """
  Takes a string and returns a time modifier
  if the string contains z u or g it's UTC
  if it contains s it's standard
  otherwise it's walltime

  ## Examples
      iex> time_modifier("10:20u")
      :utc
      iex> time_modifier("10:20")
      :wall
      iex> time_modifier("10:20 S")
      :standard
  """
  def time_modifier(string) do
    string = String.downcase string
    cond do
      Regex.match?(~r/[zug]/, string) -> :utc
      Regex.match?(~r/s/, string) -> :standard
      true -> :wall
    end
  end

  @doc """
  Takes rule and year and returns true or false depending on whether
  the rule applies for the year.

  ## Examples
      iex> rule_applies_for_year(%{at: "23:00", from: 1916, in: 5, letter: "S", name: "Denmark", on: "14", record_type: :rule, save: 3600, to: :only, type: "-"}, 1916)
      true
      iex> rule_applies_for_year(%{at: "23:00", from: 1916, in: 5, letter: "S", name: "Denmark", on: "14", record_type: :rule, save: "1:00", to: :only, type: "-"}, 2000)
      false
      iex> rule_applies_for_year(%{at: "2:00", from: 1993, in: "Oct", letter: "S", name: "Thule", on: "lastSun", record_type: :rule, save: "0", to: 2006, type: "-"}, 1993)
      true
      iex> rule_applies_for_year(%{at: "2:00", from: 1994, in: "Oct", letter: "S", name: "Thule", on: "lastSun", record_type: :rule, save: "0", to: 2006, type: "-"}, 1994)
      true
      iex> rule_applies_for_year(%{at: "2:00", from: 1994, in: "Oct", letter: "S", name: "Thule", on: "lastSun", record_type: :rule, save: "0", to: 2006, type: "-"}, 2006)
      true
      iex> rule_applies_for_year(%{at: "2:00", from: 1994, in: "Oct", letter: "S", name: "Thule", on: "lastSun", record_type: :rule, save: "0", to: 2006, type: "-"}, 2007)
      false
      iex> rule_applies_for_year(%{at: "1:00u", from: 1981, in: "Mar", letter: "S", name: "EU", on: "lastSun", record_type: :rule, save: "1:00", to: :max, type: "-"}, 2014)
      true
      iex> rule_applies_for_year(%{at: "1:00u", from: 1981, in: "Mar", letter: "S", name: "EU", on: "lastSun", record_type: :rule, save: "1:00", to: :max, type: "-"}, 1981)
      true
      iex> rule_applies_for_year(%{at: "1:00u", from: 1981, in: "Mar", letter: "S", name: "EU", on: "lastSun", record_type: :rule, save: "1:00", to: :max, type: "-"}, 1980)
      false
  """
  def rule_applies_for_year(rule, year) do
    rule_applies_for_year_h(rule[:from], rule[:to], year)
  end
  defp rule_applies_for_year_h(rule_from, :only, year) do
    rule_from == year
  end
  defp rule_applies_for_year_h(rule_from, :max, year) do
    year >= rule_from
  end
  # if we have reached this point, we assume "to" is a year number and
  # convert to integer
  defp rule_applies_for_year_h(rule_from, rule_to, year) do
    rule_applies_for_year_ints(rule_from, rule_to, year)
  end
  defp rule_applies_for_year_ints(rule_from, rule_to, year) when rule_from > year or rule_to < year do
    false
  end
  defp rule_applies_for_year_ints(_, _, _) do
    true
  end

  @doc """
  Takes a list of rules and a year.
  Returns the same list of rules except the rules that do not apply
  for the year.
  """
  def rules_for_year(rules, year) do
    rules |> Enum.filter fn(rule) -> rule_applies_for_year(rule, year) end
  end

  @doc """
  Takes a rule and a year.
  Returns the date and time of when the rule goes into effect.
  """
  def time_for_rule(rule, year) do
    {time, modifier} = rule[:at]
    month = rule[:in]
    day = tz_day_to_int year, month, rule[:on]
    {{{year, month, day}, time}, modifier}
  end

  @doc """
  Takes a zone abbreviation, a standard offset integer
  and a "letter" as found in a the letter column of a tz rule.
  Depending on whether the standard offset is 0 or not, an suitable
  abbreviation will be returned.

  ## Examples
      iex> period_abbrevation("CE%sT", 0, "-")
      "CET"
      iex> period_abbrevation("CE%sT", 3600, "S")
      "CEST"
      iex> period_abbrevation("GMT/BST", 0, "-")
      "GMT"
      iex> period_abbrevation("GMT/BST", 3600, "S")
      "BST"
  """
  def period_abbrevation(zone_abbr, std_off, letter) do
    if Regex.match?(~r/\//, zone_abbr) do
      period_abbrevation_h(:slash, zone_abbr, std_off, letter)
    else
      period_abbrevation_h(:no_slash, zone_abbr, std_off, letter)
    end
  end
  defp period_abbrevation_h(:slash, zone_abbr, 0, _) do
    map = Regex.named_captures(~r/(?<first>[^\/]+)\/(?<second>[^\/]+)/, zone_abbr)
    map["first"]
  end
  defp period_abbrevation_h(:slash, zone_abbr, _, _) do
    map = Regex.named_captures(~r/(?<first>[^\/]+)\/(?<second>[^\/]+)/, zone_abbr)
    map["second"]
  end
  defp period_abbrevation_h(:no_slash, zone_abbr, _, "-") do
    String.replace(zone_abbr, "%s", "")
  end
  defp period_abbrevation_h(:no_slash, zone_abbr, _, letter) do
    String.replace(zone_abbr, "%s", letter)
  end
end
