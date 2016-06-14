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

  @doc """
  Takes a Time struct and returns an erlang style time tuple.

  ## Examples

      iex> from_erl!({10, 20, 25}, {12345, 5}) |> to_erl
      {10, 20, 25}
      iex> {10, 20, 25} |> to_erl
      {10, 20, 25}
  """
  def to_erl(%Time{hour: hour, minute: minute, second: second}) do
    {hour, minute, second}
  end
  def to_erl(t), do: t |> contained_time |> to_erl

  @doc """
  Takes a Time struct and returns an Ecto style time four-tuple with microseconds.

  If the Time struct has its usec field set to nil, 0 will be used for usec.

  ## Examples

      iex> from_erl!({10, 20, 25}, 123456) |> to_micro_erl
      {10, 20, 25, 123456}
      # If `usec` is nil, 0 is used instead as the last element in the tuple
      iex> {10, 20, 25} |> from_erl! |> to_micro_erl
      {10, 20, 25, 0}
      iex> {10, 20, 25} |> to_micro_erl
      {10, 20, 25, 0}
  """
  def to_micro_erl(%Time{hour: hour, minute: min, second: sec, microsecond: {usec, _}}) do
    {hour, min, sec, usec}
  end
  def to_micro_erl(t), do: t |> contained_time |> to_micro_erl

  @doc """
  Create a Time struct using an erlang style tuple and optionally a microsecond second.

  Microsecond can either be a tuple of microsecond and precision. Or an integer
  with just the microsecond.

      iex> from_erl({20,14,15})
      {:ok, %Time{microsecond: {0, 0}, hour: 20, minute: 14, second: 15}}

      iex> from_erl({20,14,15}, 123456)
      {:ok, %Time{microsecond: {123456, 6}, hour: 20, minute: 14, second: 15}}

      iex> from_erl({20,14,15}, {123456, 6})
      {:ok, %Time{microsecond: {123456, 6}, hour: 20, minute: 14, second: 15}}

      iex> from_erl({24,14,15})
      {:error, :invalid_time}

      iex> from_erl({-1,0,0})
      {:error, :invalid_time}

      iex> from_erl({20,14,15}, {1_000_000, 6})
      {:error, :invalid_time}
  """
  def from_erl(_hour_minute_second_tuple, _microsecond \\ {0, 0})
  def from_erl({hour, minute, second}, microsecond) when is_integer(microsecond) do
    from_erl({hour, minute, second}, {microsecond, 6})
  end
  def from_erl({hour, minute, second}, microsecond) do
    case valid_time({hour, minute, second}, microsecond) do
      true -> {:ok, %Time{hour: hour, minute: minute, second: second, microsecond: microsecond}}
      false -> {:error, :invalid_time}
    end
  end

  @doc """
  Like from_erl, but will raise if the time is not valid.

      iex> from_erl!({20,14,15})
      %Time{microsecond: {0, 0}, hour: 20, minute: 14, second: 15}

      iex> from_erl!({20,14,15}, {123456, 6})
      %Time{microsecond: {123456, 6}, hour: 20, minute: 14, second: 15}
  """
  def from_erl!(time, microsecond \\ {0, 0}) do
    {:ok, time} = from_erl(time, microsecond)
    time
  end

  defp valid_time(time, {microsecond, precision}) do
    valid_time(time) && precision >= 0 && precision <= 6 && (microsecond >= 0 && microsecond < 1_000_000)
  end
  defp valid_time({hour, minute, second}) do
    hour >=0 and hour <= 23 and minute >= 0 and minute < 60 and second >=0 and second <= 60
  end

  @doc """
  Converts a Time to the 12 hour format

  Returns a five element tuple with:
  {hours (1-12), minutes, seconds, microseconds, :am or :pm}

  ## Examples

      iex> {13, 10, 23} |> twelve_hour_time
      {1, 10, 23, {0, 0}, :pm}
      iex> {0, 10, 23, 888888} |> twelve_hour_time
      {12, 10, 23, {888888, 6}, :am}
  """
  def twelve_hour_time(time) do
    time = time |> contained_time
    {h12, ampm} = x24h_to_12_h(time.hour)
    {h12, time.minute, time.second, time.microsecond, ampm}
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
    time
    |> contained_time
    |> to_erl
    |> :calendar.time_to_seconds
  end

  @doc """
  Create a Time struct from an integer being the number of the
  second of the day.

  00:00:00 being second 0
  and 23:59:59 being number 86399

  ## Examples

      iex> 0 |> from_second_in_day
      %Time{hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
      iex> 43200 |> from_second_in_day
      %Time{hour: 12, minute: 0, second: 0, microsecond: {0, 0}}
      iex> 86399 |> from_second_in_day
      %Time{hour: 23, minute: 59, second: 59, microsecond: {0, 0}}
  """
  def from_second_in_day(second) when second >= 0 and second <= 86399 do
    {h, m, s} = second
    |> :calendar.seconds_to_time
    %Time{hour: h, minute: m, second: s, microsecond: {0, 0}}
  end

  @doc """
  Takes a time and returns a new time with the next second.
  If the provided time is 23:59:59 it returns a Time for 00:00:00.

  ## Examples

      iex> {12, 0, 0} |> next_second
      %Time{hour: 12, minute: 0, second: 1, microsecond: {0, 0}}
      # Preserves microseconds
      iex> {12, 0, 0, 123456} |> next_second
      %Time{hour: 12, minute: 0, second: 1, microsecond: {123456, 6}}
      # At the end of the day it goes to 00:00:00
      iex> {23, 59, 59} |> next_second
      %Time{hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
      iex> {23, 59, 59, 300000} |> next_second
      %Time{hour: 0, minute: 0, second: 0, microsecond: {300000, 6}}
  """
  def next_second(time), do: time |> contained_time |> do_next_second
  defp do_next_second(%Time{hour: 23, minute: 59, second: second, microsecond: microsecond}) when second >= 59 do
    %Time{hour: 0, minute: 0, second: 0, microsecond: microsecond}
  end
  defp do_next_second(time) do
    time
    |> second_in_day
    |> Kernel.+(1)
    |> from_second_in_day
    |> add_usec_to_time(time.microsecond)
  end
  defp add_usec_to_time(time, nil), do: time
  defp add_usec_to_time(time, microsecond) do
    %{time | :microsecond => microsecond}
  end

  @doc """
  Takes a time and returns a new time with the previous second.
  If the provided time is 00:00:00 it returns a Time for 23:59:59.

  ## Examples

      iex> {12, 0, 0} |> prev_second
      %Time{hour: 11, minute: 59, second: 59, microsecond: {0, 0}}
      # Preserves microseconds
      iex> {12, 0, 0, 123456} |> prev_second
      %Time{hour: 11, minute: 59, second: 59, microsecond: {123456, 6}}
      # At the beginning of the day it goes to 23:59:59
      iex> {0, 0, 0} |> prev_second
      %Time{hour: 23, minute: 59, second: 59, microsecond: {0, 0}}
      iex> {0, 0, 0, 200_000} |> prev_second
      %Time{hour: 23, minute: 59, second: 59, microsecond: {200_000, 6}}
  """
  def prev_second(time), do: time |> contained_time |> do_prev_second
  defp do_prev_second(%Time{hour: 0, minute: 0, second: 0, microsecond: microsecond}) do
    %Time{hour: 23, minute: 59, second: 59, microsecond: microsecond}
  end
  defp do_prev_second(time) do
    time
    |> second_in_day
    |> Kernel.-(1)
    |> from_second_in_day
    |> add_usec_to_time(time.microsecond)
  end

  defp x24h_to_12_h(0) do {12, :am} end
  defp x24h_to_12_h(12) do {12, :pm} end
  defp x24h_to_12_h(hour) when hour >= 1 and hour < 12 do {hour, :am} end
  defp x24h_to_12_h(hour) when hour > 12 do {hour - 12, :pm} end

  @doc """
  Difference in seconds between two times.

  Takes two Time structs: `first_time` and `second_time`.
  Subtracts `second_time` from `first_time`.

      iex> from_erl!({0, 0, 30}) |> diff(from_erl!({0, 0, 10}))
      20
      iex> from_erl!({0, 0, 10}) |> diff(from_erl!({0, 0, 30}))
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

      iex> {8, 10, 23} |> Calendar.Time.am?
      true
      iex> {20, 10, 23} |> Calendar.Time.am?
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

      iex> {8, 10, 23} |> Calendar.Time.pm?
      false
      iex> {20, 10, 23} |> Calendar.Time.pm?
      true
  """
  def pm?(time) do
    {_, _, _, _, ampm} = twelve_hour_time(time)
    ampm == :pm
  end

  defp contained_time(time_container), do: Calendar.ContainsTime.time_struct(time_container)
end

defimpl Calendar.ContainsTime, for: Time do
  def time_struct(data), do: data
end
defimpl Calendar.ContainsTime, for: DateTime do
  def time_struct(data) do
    %Time{hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond}
  end
end
defimpl Calendar.ContainsTime, for: NaiveDateTime do
  def time_struct(data) do
    data |> Calendar.NaiveDateTime.to_time
  end
end
defimpl Calendar.ContainsTime, for: Tuple do
  def time_struct({h, m, s}), do: Time.from_erl!({h, m, s})
  def time_struct({h, m, s, usec}), do: Time.from_erl!({h, m, s}, {usec, 6})
  # datetime tuple
  def time_struct({{_,_,_},{h, m, s}}), do: Time.from_erl!({h, m, s})
  # datetime tuple with microseconds
  def time_struct({{_,_,_},{h, m, s, usec}}), do: Time.from_erl!({h, m, s}, {usec, 6})
end
defimpl Calendar.ContainsTime, for: Calendar.DateTime do
  def time_struct(data) do
    %Time{hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond}
  end
end
defimpl Calendar.ContainsTime, for: Calendar.NaiveDateTime do
  def time_struct(data) do
    %Time{hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond}
  end
end
