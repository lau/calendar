defmodule Calendar.Date.Parse do
  alias Calendar.Date
  #import Calendar.ParseUtil

  @doc """
  Parses ISO 8601 date strings.

  The function accepts both the extended and the basic format.

  ## Examples

      # Extended format
      iex> iso8601("2016-01-05")
      {:ok, %Calendar.Date{year: 2016, month: 1, day: 5}}
      # Basic format (the basic format does not have dashes)
      iex> iso8601("20160105")
      {:ok, %Calendar.Date{year: 2016, month: 1, day: 5}}
      iex> iso8601("2016-99-05")
      {:error, :invalid_date}
  """
  def iso8601(string) do
    Calendar.NaiveDateTime.Parse.iso8601(string<>"T00:00:00")
    |> iso8610result
  end
  defp iso8610result({:ok, ndt, _}), do: {:ok, ndt |> Calendar.NaiveDateTime.to_date}
  defp iso8610result({:error, :invalid_datetime, _}), do: {:error, :invalid_date}
  defp iso8610result({first, second, _}), do: {first, second}

  @doc """
  Parses ISO 8601 week date strings.

  ## Examples

      iex> iso_week_date("2004-W53-6")
      {:ok, %Calendar.Date{year: 2005, month: 1, day: 1}}
      iex> iso_week_date("2008-W01-2")
      {:ok, %Calendar.Date{year: 2008, month: 1, day: 1}}
      iex> iso_week_date("2004-W53-6D")
      {:ok, %Calendar.Date{year: 2005, month: 1, day: 1}}
      iex> iso_week_date("2004-W53-9")
      :error
      iex> iso_week_date("2004-W54-9")
      :error
      iex> iso_week_date("2004-W0-9")
      :error
  """
  def iso_week_date(string) do
    try do
      string
      |> String.replace("D", "")
      |> do_iso_week_date
    rescue
      _ -> :error
    end
  end
  defp do_iso_week_date(<<binyear::4-bytes, ?-, ?W, binweek::2-bytes, ?-, bday::1-bytes>>) do
    {year, ""} = binyear |> Integer.parse
    {week, ""} = binweek |> Integer.parse
    {day, ""}  = bday |> Integer.parse
    date = Date.dates_for_week_number(year, week)
    |> List.to_tuple
    |> elem((day-1))
    {:ok, date}
  end
end
