defmodule Kalends.NaiveDateTime do
  @moduledoc """
  NaiveDateTime can represents a "naive time". That is a point in time without
  a specified time zone.
  """
  defstruct [:year, :month, :day, :hour, :min, :sec]

  @doc """
  Like from_erl/1 without "!", but returns the result directly without a tag.
  Will raise if date is invalid. Only use this if you are sure the date is valid.

  ## Examples

      iex> from_erl!({{2014, 9, 26}, {17, 10, 20}})
      %Kalends.NaiveDateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014}

      iex from_erl!({{2014, 99, 99}, {17, 10, 20}})
      # this will throw a MatchError
  """
  def from_erl!(erl_date_time) do
    {:ok, result} = from_erl(erl_date_time)
    result
  end

  @doc """
  Takes an Erlang-style date-time tuple.
  If the datetime is valid it returns a tuple with a tag and a naive DateTime.
  Naive in this context means that it does not have any timezone data.

  ## Examples
      iex> from_erl({{2014, 9, 26}, {17, 10, 20}})
      {:ok, %Kalends.NaiveDateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014} }

      iex> from_erl({{2014, 99, 99}, {17, 10, 20}})
      {:error, :invalid_datetime}
  """
  def from_erl({{year, month, day}, {hour, min, sec}}) do
    if validate_erl_datetime {{year, month, day}, {hour, min, sec}} do
      {:ok, %Kalends.NaiveDateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec} }
    else
      {:error, :invalid_datetime}
    end
  end

  defp validate_erl_datetime({date, _}) do
    :calendar.valid_date date
  end

  @doc """
  Takes a NaiveDateTime struct and returns an erlang style datetime tuple.

  ## Examples

      iex> from_erl!({{2014, 10, 15}, {2, 37, 22}}) |> to_erl
      {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%Kalends.NaiveDateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec}) do
    {{year, month, day}, {hour, min, sec}}
  end
end
