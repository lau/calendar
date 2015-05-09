defmodule Kalends.Date do
  @moduledoc """
  The Date module provides a struct to represent a simple date: year, month and day.
  """

  defstruct [:year, :month, :day]

  @doc """
  Takes a Date struct and returns an erlang style date tuple.
  """
  def to_erl(%Kalends.Date{year: year, month: month, day: day}) do
    {year, month, day}
  end

  @doc """
  Takes a erlang style date tuple and returns a tuple with an :ok tag and a
  Date struct. If the provided date is invalid, it will not be tagged with :ok
  though as shown below:

      iex> from_erl({2014,12,27})
      {:ok, %Kalends.Date{day: 27, month: 12, year: 2014}}

      iex> from_erl({2014,99,99})
      {:error, :invalid_date}
  """
  def from_erl({year, month, day}) do
    if :calendar.valid_date({year, month, day}) do
      {:ok, %Kalends.Date{year: year, month: month, day: day}}
    else
      {:error, :invalid_date}
    end
  end

  @doc """
  Like from_erl without the exclamation point, but does not return a tuple
  with a tag. Instead returns just a Date if valid. Or raises an exception if
  the provided date is invalid.

      iex> from_erl! {2014,12,27}
      %Kalends.Date{day: 27, month: 12, year: 2014}
  """
  def from_erl!(erl_date) do
    {:ok, date} = from_erl(erl_date)
    date
  end

  @doc """
  Takes a Date struct and returns the number of days in the month of that date.
  The day of the date provided does not matter - the result is based on the
  month and the year.

      iex> from_erl!({2014,12,27}) |> number_of_days_in_month
      31
      iex> from_erl!({2015,2,27}) |> number_of_days_in_month
      28
      iex> from_erl!({2012,2,27}) |> number_of_days_in_month
      29
  """
  def number_of_days_in_month(date) do
    {year, month, _} = date |> to_erl
    :calendar.last_day_of_the_month(year, month)
  end

  @doc """
  Takes a Date struct and returns a tuple with the ISO week number
  and the year that the week belongs to.
  Note that the year returned does not always match the year provided.

      iex> from_erl!({2014,12,31}) |> week_number
      {2015, 1}
      iex> from_erl!({2014,12,27}) |> week_number
      {2014, 52}
  """
  def week_number(date) do
    :calendar.iso_week_number(date|>to_erl)
  end

  @doc """
  Takes a Date struct and returns the number of gregorian days since year 0.

      iex> from_erl!({2014,12,27}) |> to_gregorian_days
      735959
  """
  def to_gregorian_days(date) do
    :calendar.date_to_gregorian_days(date.year, date.month, date.day)
  end

  defp from_gregorian_days!(days) do
    :calendar.gregorian_days_to_date(days) |> from_erl!
  end

  @doc """
  Takes a Date struct and returns another one representing the next day.

      iex> from_erl!({2014,12,27}) |> next_day
      %Kalends.Date{day: 28, month: 12, year: 2014}
      iex> from_erl!({2014,12,31}) |> next_day
      %Kalends.Date{day: 1, month: 1, year: 2015}
  """
  def next_day(date) do
    to_gregorian_days(date)+1
    |> from_gregorian_days!
  end

  @doc """
  Takes a Date struct and returns another one representing the previous day.

      iex> from_erl!({2014,12,27}) |> prev_day
      %Kalends.Date{day: 26, month: 12, year: 2014}
  """
  def prev_day(date) do
    to_gregorian_days(date)-1
    |> from_gregorian_days!
  end

  @doc """
  Difference in days between two dates.

  Takes two Date structs: `first_date` and `second_date`.
  Subtracts `second_date` from `first_date`.

      iex> from_erl!({2014,12,27}) |> diff from_erl!({2014,12,20})
      7
      iex> from_erl!({2014,12,27}) |> diff from_erl!({2014,12,29})
      -2
  """
  def diff(%Kalends.Date{} = first_date, %Kalends.Date{} = second_date) do
    to_gregorian_days(first_date) -to_gregorian_days(second_date)
  end

  @doc """
  Get a stream of dates. Takes a starting date and an optional end date. Includes both start and end date.

      iex> stream(from_erl!({2014,12,27}), from_erl!({2014,12,29})) |> Enum.to_list
      [%Kalends.Date{day: 27, month: 12, year: 2014}, %Kalends.Date{day: 28, month: 12, year: 2014}, %Kalends.Date{day: 29, month: 12, year: 2014}]
      iex> stream(from_erl!({2014,12,27})) |> Enum.take(7)
      [%Kalends.Date{day: 27, month: 12, year: 2014}, %Kalends.Date{day: 28, month: 12, year: 2014}, %Kalends.Date{day: 29, month: 12, year: 2014},
            %Kalends.Date{day: 30, month: 12, year: 2014}, %Kalends.Date{day: 31, month: 12, year: 2014}, %Kalends.Date{day: 1, month: 1, year: 2015},
            %Kalends.Date{day: 2, month: 1, year: 2015}]
  """
  def stream(from_date, until_date) do
    Stream.unfold(from_date, fn n -> if n == next_day(until_date) do nil else {n, n |> next_day} end end)
  end
  def stream(from_date) do
    Stream.unfold(from_date, fn n -> {n, n |> next_day} end)
  end
end
