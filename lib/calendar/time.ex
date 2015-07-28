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
      0
      iex> {23, 59, 59} |> second_in_day
      86399
  """
  def second_in_day(time) do
    time = time |> contained_time
    time
    |> to_erl
    |> :calendar.time_to_seconds
  end

  @doc """
  Create a Calendar.Time struct from an integer being the number of the
  second of the day.

  00:00:00 being second 0
  and 23:59:59 being number 86399

  ## Examples

      iex> 0 |> from_second_in_day
      %Calendar.Time{hour: 0, min: 0, sec: 0, usec: nil}
      iex> 43200 |> from_second_in_day
      %Calendar.Time{hour: 12, min: 0, sec: 0, usec: nil}
      iex> 86399 |> from_second_in_day
      %Calendar.Time{hour: 23, min: 59, sec: 59, usec: nil}
  """
  def from_second_in_day(second) when second >= 0 and second <= 86399 do
    {h, m, s} = second
    |> :calendar.seconds_to_time
    %Calendar.Time{hour: h, min: m, sec: s}
  end

  @doc """
  Takes a time and returns a new time with the next second.
  If the provided time is 23:59:59 it returns a Time for 00:00:00.

  ## Examples

      iex> {12, 0, 0} |> next_second
      %Calendar.Time{hour: 12, min: 0, sec: 1, usec: nil}
      # Preserves microseconds
      iex> {12, 0, 0, 123456} |> next_second
      %Calendar.Time{hour: 12, min: 0, sec: 1, usec: 123456}
      # At the end of the day it goes to 00:00:00
      iex> {23, 59, 59} |> next_second
      %Calendar.Time{hour: 0, min: 0, sec: 0, usec: nil}
      iex> {23, 59, 59, 300000} |> next_second
      %Calendar.Time{hour: 0, min: 0, sec: 0, usec: 300000}
  """
  def next_second(time), do: time |> contained_time |> do_next_second
  defp do_next_second(%Calendar.Time{hour: 23, min: 59, sec: sec, usec: usec}) when sec >= 59 do
    %Calendar.Time{hour: 0, min: 0, sec: 0, usec: usec}
  end
  defp do_next_second(time) do
    time
    |> second_in_day
    |> +1
    |> from_second_in_day
    |> add_usec_to_time(time.usec)
  end
  defp add_usec_to_time(time, nil), do: time
  defp add_usec_to_time(time, usec) do
    %{time | :usec => usec}
  end

  @doc """
  Takes a time and returns a new time with the previous second.
  If the provided time is 00:00:00 it returns a Time for 23:59:59.

  ## Examples

      iex> {12, 0, 0} |> prev_second
      %Calendar.Time{hour: 11, min: 59, sec: 59, usec: nil}
      # Preserves microseconds
      iex> {12, 0, 0, 123456} |> prev_second
      %Calendar.Time{hour: 11, min: 59, sec: 59, usec: 123456}
      # At the beginning of the day it goes to 23:59:59
      iex> {0, 0, 0} |> prev_second
      %Calendar.Time{hour: 23, min: 59, sec: 59, usec: nil}
      iex> {0, 0, 0, 200_000} |> prev_second
      %Calendar.Time{hour: 23, min: 59, sec: 59, usec: 200_000}
  """
  def prev_second(time), do: time |> contained_time |> do_prev_second
  defp do_prev_second(%Calendar.Time{hour: 0, min: 0, sec: 0, usec: usec}) do
    %Calendar.Time{hour: 23, min: 59, sec: 59, usec: usec}
  end
  defp do_prev_second(time) do
    time
    |> second_in_day
    |> -1
    |> from_second_in_day
    |> add_usec_to_time(time.usec)
  end

  defp x24h_to_12_h(0) do {12, :am} end
  defp x24h_to_12_h(12) do {12, :pm} end
  defp x24h_to_12_h(hour) when hour >= 1 and hour < 12 do {hour, :am} end
  defp x24h_to_12_h(hour) when hour > 12 do {hour - 12, :pm} end

  @doc """
  Difference in seconds between two times.

  Takes two Time structs: `first_time` and `second_time`.
  Subtracts `second_time` from `first_time`.

      iex> from_erl!({0, 0, 30}) |> diff from_erl!({0, 0, 10})
      20
      iex> from_erl!({0, 0, 10}) |> diff from_erl!({0, 0, 30})
      -20
  """
  def diff(first_time_cont, second_time_cont) do
    first_time = contained_time(first_time_cont)
    second_time = contained_time(second_time_cont)
    second_in_day(first_time) - second_in_day(second_time)
  end

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

defimpl Range.Iterator, for: Calendar.Time do
  alias Calendar.Time
  def next(first, _ .. last) do
    if (Time.second_in_day(last)-Time.second_in_day(first))>=0  do
      &(&1 |> Time.next_second)
    else
      &(&1 |> Time.prev_second)
    end
  end

  def count(first, _ .. last) do
    (Time.second_in_day(first)-Time.second_in_day(last))
    |> abs
  end
end
