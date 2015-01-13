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

  def from_erl!(erl_date) do
    {:ok, date} = from_erl(erl_date)
    date
  end

  @doc """
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
end
