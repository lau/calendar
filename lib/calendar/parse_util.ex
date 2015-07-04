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
end
