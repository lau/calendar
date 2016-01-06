defmodule Calendar.Date.Format do
  alias Calendar.Date
  alias Calendar.Strftime

  @doc """
  Format a date as ISO 8601 extended format

  ## Examples

      iex> {2015, 4, 3} |> iso8601
      "2015-04-03"
  """
  def iso8601(date) do
    date
    |> contained_date
    |> Strftime.strftime!("%Y-%m-%d")
  end

  @doc """
  Format a date as ISO 8601 basic format

  ## Examples

      iex> {2015, 4, 3} |> iso8601_basic
      "20150403"
  """
  def iso8601_basic(date) do
    date
    |> contained_date
    |> Strftime.strftime!("%Y%m%d")
  end

  @doc """
  Format a date as ISO 8601 ordinal format

  ## Examples

      iex> {2015, 4, 3} |> ordinal
      "2015-093"
  """
  def ordinal(date) do
    date
    |> contained_date
    |> Strftime.strftime!("%Y-%j")
  end

  @doc """
  Format a date as ISO 8601 year and week number. Without weekday.

  ## Examples

      iex> {2015, 4, 3} |> week_number
      "2015-W14"
  """
  def week_number(date) do
    date
    |> contained_date
    |> Strftime.strftime!("%Y-W%V")
  end


  @doc """
  Format a date as ISO 8601 year and week number. With weekday.

  ## Examples

      iex> {2015, 4, 3} |> week_number_day
      "2015-W14-5"
  """
  def week_number_day(date) do
    date
    |> contained_date
    |> Strftime.strftime!("%Y-W%V-%u")
  end

  defp contained_date(date_container), do: Calendar.ContainsDate.date_struct(date_container)
end
