defmodule Calendar.NaiveDateTime.Format do
  alias Calendar.Strftime

  @doc """
  Format a naive datetime as "c time"

  ## Examples
      iex> {{2015, 3, 3}, {7, 5, 3}} |> asctime
      "Tue Mar  3 07:05:03 2015"
  """
  def asctime(ndt) do
    ndt
    |> to_utc_dt
    |> Strftime.strftime!("%c")
  end

  @doc """
  Format a naive datetime as ISO 8601 in extended format.

  ## Examples
      iex> {{2015, 4, 3}, {7, 5, 3}} |> iso8601
      "2015-04-03T07:05:03"
  """
  def iso8601(ndt) do
    ndt
    |> to_utc_dt
    |> Strftime.strftime!("%FT%T")
  end

  defp to_utc_dt(ndt) do
    ndt |> Calendar.NaiveDateTime.to_date_time_utc
  end

  @doc """
  Format a naive datetime as ISO 8601 in basic format.

  ## Examples
      iex> {{2015, 4, 3}, {7, 5, 3}} |> iso8601_basic
      "20150403T070503"
  """
  def iso8601_basic(ndt) do
    ndt
    |> to_utc_dt
    |> Strftime.strftime!("%FT%T")
    |> String.replace(":", "")
    |> String.replace("-", "")
  end
end
