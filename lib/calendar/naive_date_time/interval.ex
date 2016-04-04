defmodule Calendar.NaiveDateTime.Interval do
@moduledoc """
A `NaiveDateTime.Interval` consists of a start and an end `NaiveDateTime`.
"""
  @type t :: %__MODULE__{from: %NaiveDateTime{}, to: %NaiveDateTime{}}
  defstruct [:from, :to]

  @doc """
  Formats interval in ISO 8601 extended format.

  ## Example:

      # With a `NaiveDateTime.Interval`
      iex> %Calendar.NaiveDateTime.Interval{from: {{2016, 2, 27}, {10, 0, 0}} |> Calendar.NaiveDateTime.from_erl!, to: {{2016, 3, 1}, {11, 0, 0}} |> Calendar.NaiveDateTime.from_erl!} |> Calendar.NaiveDateTime.Interval.iso8601
      "2016-02-27T10:00:00/2016-03-01T11:00:00"
      # Also works with a `DateTime.Interval`
      iex> %Calendar.DateTime.Interval{from: {{2016, 2, 27}, {10, 0, 0}} |> Calendar.DateTime.from_erl!("Etc/UTC"), to: {{2016, 3, 1}, {11, 0, 0}} |> Calendar.DateTime.from_erl!("Etc/UTC")} |> Calendar.NaiveDateTime.Interval.iso8601
      "2016-02-27T10:00:00/2016-03-01T11:00:00"
  """
  def iso8601(interval) do
    from_string = interval.from |> Calendar.NaiveDateTime.Format.iso8601
    to_string   = interval.to   |> Calendar.NaiveDateTime.Format.iso8601
    from_string <> "/" <> to_string
  end

  @doc """
  Formats interval in ISO 8601 basic format.

  ## Example:

      iex> %Calendar.NaiveDateTime.Interval{from: {{2016, 2, 27}, {10, 0, 0}}, to: {{2016, 3, 1}, {11, 0, 0}}} |> Calendar.NaiveDateTime.Interval.iso8601_basic
      "20160227T100000/20160301T110000"
      # Also works with a `Calendar.DateTime.Interval`
      iex> %Calendar.DateTime.Interval{from: {{2016, 2, 27}, {10, 0, 0}} |> Calendar.DateTime.from_erl!("Etc/UTC"), to: {{2016, 3, 1}, {11, 0, 0}} |> Calendar.DateTime.from_erl!("Etc/UTC")} |> Calendar.NaiveDateTime.Interval.iso8601_basic
      "20160227T100000/20160301T110000"
  """
  def iso8601_basic(interval) do
    from_string = interval.from |> Calendar.NaiveDateTime.Format.iso8601_basic
    to_string   = interval.to   |> Calendar.NaiveDateTime.Format.iso8601_basic
    from_string <> "/" <> to_string
  end
end
