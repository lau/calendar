defmodule Kalends.Time do
  @moduledoc """
  The Time module provides a struct to represent a simple time without
  specifying a date, nor a time zone.
  """
  defstruct [:hour, :min, :sec, :usec]

  @doc """
  Takes a Time struct and returns an erlang style time tuple.
  """
  def to_erl(%Kalends.Time{hour: hour, min: min, sec: sec}) do
    {hour, min, sec}
  end

  @doc """
  Create a Time struct using an erlang style tuple and optionally a fractional second.

      iex> from_erl({20,14,15})
      {:ok, %Kalends.Time{usec: nil, hour: 20, min: 14, sec: 15}}

      iex> from_erl({20,14,15}, 123456)
      {:ok, %Kalends.Time{usec: 123456, hour: 20, min: 14, sec: 15}}

      iex> from_erl({24,14,15})
      {:error, :invalid_time}

      iex> from_erl({-1,0,0})
      {:error, :invalid_time}

      iex> from_erl({20,14,15}, 1_000_000)
      {:error, :invalid_time}
  """
  def from_erl({hour, min, sec}, usec\\nil) do
    if valid_time({hour, min, sec}, usec) do
      {:ok, %Kalends.Time{hour: hour, min: min, sec: sec, usec: usec}}
    else
      {:error, :invalid_time}
    end
  end

  defp valid_time(time, usec) do
    valid_time(time) && (usec==nil || (usec >= 0 && usec < 1_000_000))
  end
  defp valid_time({hour, min, sec}) when (hour >=0 and hour <= 23 and min >= 0 and min < 60 and sec >=0 and sec <= 60) do
    true
  end
  defp valid_time({_hour, _min, _sec}) do
    false
  end
end
