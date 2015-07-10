defprotocol Calendar.ContainsTime do
  @doc """
  Returns a Calendar.Time struct for the provided argument
  """
  def time_struct(data)
end

defmodule Calendar.Time do
  @moduledoc """
  The Time module provides a struct to represent a simple time without
  specifying a date, nor a time zone.
  """
  defstruct [:hour, :min, :sec, :usec]

  @doc """
  Takes a Time struct and returns an erlang style time tuple.
  """
  def to_erl(%Calendar.Time{hour: hour, min: min, sec: sec}) do
    {hour, min, sec}
  end

  @doc """
  Create a Time struct using an erlang style tuple and optionally a fractional second.

      iex> from_erl({20,14,15})
      {:ok, %Calendar.Time{usec: nil, hour: 20, min: 14, sec: 15}}

      iex> from_erl({20,14,15}, 123456)
      {:ok, %Calendar.Time{usec: 123456, hour: 20, min: 14, sec: 15}}

      iex> from_erl({24,14,15})
      {:error, :invalid_time}

      iex> from_erl({-1,0,0})
      {:error, :invalid_time}

      iex> from_erl({20,14,15}, 1_000_000)
      {:error, :invalid_time}
  """
  def from_erl({hour, min, sec}, usec\\nil) do
    if valid_time({hour, min, sec}, usec) do
      {:ok, %Calendar.Time{hour: hour, min: min, sec: sec, usec: usec}}
    else
      {:error, :invalid_time}
    end
  end

  @doc """
  Like from_erl, but will raise if the time is not valid.

      iex> from_erl!({20,14,15})
      %Calendar.Time{usec: nil, hour: 20, min: 14, sec: 15}

      iex> from_erl!({20,14,15}, 123456)
      %Calendar.Time{usec: 123456, hour: 20, min: 14, sec: 15}
  """
  def from_erl!(time, usec\\nil) do
    {:ok, time} = from_erl(time, usec)
    time
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

  @doc """
  Converts a Time to the 12 hour format

  Returns a five element tuple with:
  {hours (1-12), minutes, seconds, microseconds, :am or :pm}

  ## Examples

      iex> {13, 10, 23} |> twelve_hour_time
      {1, 10, 23, nil, :pm}
      iex> {0, 10, 23, 888888} |> twelve_hour_time
      {12, 10, 23, 888888, :am}
  """
  def twelve_hour_time(time) do
    time = time |> contained_time
    {h12, ampm} = x24h_to_12_h(time.hour)
    {h12, time.min, time.sec, time.usec, ampm}
  end

  @doc """
  The number of the second in the day with 00:00:00 being second 1
  and 23:59:59 being number 86400

  ## Examples

      iex> {0, 0, 0} |> second_in_day
      1
      iex> {23, 59, 59} |> second_in_day
      86400
  """
  def second_in_day(time) do
    time = time |> contained_time
    ndt = Calendar.NaiveDateTime.from_erl!({{0,1,1}, time|>to_erl})
    ndt |> Calendar.NaiveDateTime.gregorian_seconds
    |> +1
  end

  @doc """
  Create a Calendar.Time struct from an integer being the number of the
  second of the day.

  00:00:00 being second 1
  and 23:59:59 being number 86400

  ## Examples

      iex> 1 |> from_second_in_day
      {0, 0, 0}
      iex> 43201 |> from_second_in_day
      {12, 0, 0}
      iex> 86400 |> from_second_in_day
      {23, 59, 59}
  """
  def from_second_in_day(second) when second >= 1 and second <= 86400 do
    {_date, time} = second
    |> -1
    |>:calendar.gregorian_seconds_to_datetime
    time
  end

  defp x24h_to_12_h(0) do {12, :am} end
  defp x24h_to_12_h(12) do {12, :pm} end
  defp x24h_to_12_h(hour) when hour >= 1 and hour < 12 do {hour, :am} end
  defp x24h_to_12_h(hour) when hour > 12 do {hour - 12, :pm} end

  @doc """
  Returns true if provided time is AM in the twelve hour clock
  system. Otherwise false.

  ## Examples

      iex> {8, 10, 23} |> Time.am?
      true
      iex> {20, 10, 23} |> Time.am?
      false
  """
  def am?(time) do
    {_, _, _, _, ampm} = twelve_hour_time(time)
    ampm == :am
  end

  @doc """
  Returns true if provided time is AM in the twelve hour clock
  system. Otherwise false.

  ## Examples

      iex> {8, 10, 23} |> Time.pm?
      false
      iex> {20, 10, 23} |> Time.pm?
      true
  """
  def pm?(time) do
    {_, _, _, _, ampm} = twelve_hour_time(time)
    ampm == :pm
  end

  defp contained_time(time_container), do: Calendar.ContainsTime.time_struct(time_container)
end

defimpl Calendar.ContainsTime, for: Calendar.Time do
  def time_struct(data), do: data
end
defimpl Calendar.ContainsTime, for: Calendar.DateTime do
  def time_struct(data) do
    data |> Calendar.DateTime.to_time
  end
end
defimpl Calendar.ContainsTime, for: Calendar.NaiveDateTime do
  def time_struct(data) do
    data |> Calendar.NaiveDateTime.to_time
  end
end
defimpl Calendar.ContainsTime, for: Tuple do
  def time_struct({h, m, s}), do: Calendar.Time.from_erl!({h, m, s})
  def time_struct({h, m, s, usec}), do: Calendar.Time.from_erl!({h, m, s}, usec)
  # datetime tuple
  def time_struct({{_,_,_},{h, m, s}}), do: Calendar.Time.from_erl!({h, m, s})
  # datetime tuple with microseconds
  def time_struct({{_,_,_},{h, m, s, usec}}), do: Calendar.Time.from_erl!({h, m, s}, usec)
end
