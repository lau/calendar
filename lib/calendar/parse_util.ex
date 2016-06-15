defmodule Calendar.ParseUtil do
  @moduledoc false

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
  # By returning 0 for invalid month names, we have a valid int to pass to
  # DateTime.from_erl that will return a nice error. This way we avoid an
  # exception when parsing an httpdate with an invalid month name.
  defp cap_month_number_for_month_name(_), do: 0

  def to_int(string) do
    {int, _} = Integer.parse(string)
    int
  end

  def capture_rfc2822_string(string) do
    ~r/(?<day>[\d]{1,2})[\s]+(?<month>[^\d]{3})[\s]+(?<year>[\d]{4})[\s]+(?<hour>[\d]{2})[^\d]?(?<min>[\d]{2})[^\d]?(?<sec>[\d]{2})[^\d]?(((?<offset_sign>[+-])(?<offset_hours>[\d]{2})(?<offset_mins>[\d]{2})|(?<offset_letters>[A-Z]{1,3})))?/
    |> Regex.named_captures(string)
  end

  # Takes strings of hours and mins and return secs
  def hours_mins_to_secs!(hours, mins) do
    hours_int = hours |> to_int
    mins_int = mins |> to_int
    hours_int*3600+mins_int*60
  end

  def two_to_four_digit_year(year, year_guessing_base) when year < 100 do
    closest_year(year, year_guessing_base)
  end
  def two_to_four_digit_year(year, _), do: year

  defp closest_year(two_digit_year, year_guessing_base) do
    two_digit_year
    |> possible_years(year_guessing_base)
    |> Enum.map(fn year -> {year, abs(year_guessing_base-year)} end)
    |> Enum.min_by(fn {_year, diff} -> diff end)
    |> elem(0)
  end
  defp possible_years(two_digit_year, year_guessing_base) do
    centuries_for_guessing_base(year_guessing_base)
    |> Enum.map(&(&1+two_digit_year))
  end
  # The three centuries closest to the guessing base
  # if you provide e.g. 2015 it should return [1900, 2000, 2100]
  defp centuries_for_guessing_base(year_guessing_base) do
    base_century = year_guessing_base-rem(year_guessing_base, 100)
    [base_century-100, base_century, base_century+100]
  end
end
