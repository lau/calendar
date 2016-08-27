defprotocol Calendar.ContainsNaiveDateTime do
  @doc """
  Returns a Calendar.NaiveDateTime struct for the provided data
  """
  def ndt_struct(data)
end

defmodule Calendar.NaiveDateTime do
  require Calendar.DateTime.Format

  @moduledoc """
  NaiveDateTime can represents a "naive time". That is a point in time without
  a specified time zone.
  """

  @doc """
  Like from_erl/1 without "!", but returns the result directly without a tag.
  Will raise if date is invalid. Only use this if you are sure the date is valid.

  ## Examples

      iex> from_erl!({{2014, 9, 26}, {17, 10, 20}})
      %NaiveDateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20, year: 2014}

      iex from_erl!({{2014, 99, 99}, {17, 10, 20}})
      # this will throw a MatchError
  """
  def from_erl!(erl_date_time, microsecond \\ {0, 0}) do
    {:ok, result} = from_erl(erl_date_time, microsecond)
    result
  end

  @doc """
  Takes an Erlang-style date-time tuple.
  If the datetime is valid it returns a tuple with a tag and a naive DateTime.
  Naive in this context means that it does not have any timezone data.

  ## Examples

      iex>from_erl({{2014, 9, 26}, {17, 10, 20}})
      {:ok, %NaiveDateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20, year: 2014} }

      iex>from_erl({{2014, 9, 26}, {17, 10, 20}}, 321321)
      {:ok, %NaiveDateTime{day: 26, hour: 17, minute: 10, month: 9, second: 20, year: 2014, microsecond: {321321, 6}} }

      # Invalid date
      iex>from_erl({{2014, 99, 99}, {17, 10, 20}})
      {:error, :invalid_datetime}

      # Invalid time
      iex>from_erl({{2014, 9, 26}, {17, 70, 20}})
      {:error, :invalid_datetime}
  """
  def from_erl(dt, microsecond \\ {0, 0})
  def from_erl({{year, month, day}, {hour, min, sec}}, microsecond) when is_integer(microsecond) do
    from_erl({{year, month, day}, {hour, min, sec}}, {microsecond, 6})
  end
  def from_erl({{year, month, day}, {hour, min, sec}}, microsecond) do
    if validate_erl_datetime {{year, month, day}, {hour, min, sec}} do
      {:ok, %NaiveDateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, microsecond: microsecond}}
    else
      {:error, :invalid_datetime}
    end
  end

  defp validate_erl_datetime({date, time}) do
    {time_tag, _ } = Calendar.Time.from_erl(time)
    :calendar.valid_date(date) && time_tag == :ok
  end

  @doc """
  Takes a NaiveDateTime struct and returns an erlang style datetime tuple.

  ## Examples

      iex> from_erl!({{2014, 10, 15}, {2, 37, 22}}) |> to_erl
      {{2014, 10, 15}, {2, 37, 22}}
  """
  def to_erl(%NaiveDateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec}) do
    {{year, month, day}, {hour, min, sec}}
  end
  def to_erl(ndt) do
    ndt |> contained_ndt |> to_erl
  end

  @doc """
  Takes a NaiveDateTime struct and returns an Ecto style datetime tuple. This is
  like an erlang style tuple, but with microseconds added as an additional
  element in the time part of the tuple.

  If the datetime has its microsecond field set to nil, 0 will be used for microsecond.

  ## Examples

      iex> from_erl!({{2014,10,15},{2,37,22}}, {999999, 6}) |> Calendar.NaiveDateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 999999}}

      iex> from_erl!({{2014,10,15},{2,37,22}}, {0, 0}) |> Calendar.NaiveDateTime.to_micro_erl
      {{2014, 10, 15}, {2, 37, 22, 0}}
  """
  def to_micro_erl(%NaiveDateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, microsecond: {0, _}}) do
    {{year, month, day}, {hour, min, sec, 0}}
  end
  def to_micro_erl(%NaiveDateTime{year: year, month: month, day: day, hour: hour, minute: min, second: sec, microsecond: {microsecond, _}}) do
    {{year, month, day}, {hour, min, sec, microsecond}}
  end
  def to_micro_erl(ndt) do
    ndt |> contained_ndt |> to_micro_erl
  end

  @doc """
  Takes a NaiveDateTime struct and returns a Date struct representing the date part
  of the provided NaiveDateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Calendar.NaiveDateTime.to_date
      %Date{day: 15, month: 10, year: 2014}
  """
  def to_date(ndt) do
    ndt = ndt |> contained_ndt
    %Date{year: ndt.year, month: ndt.month, day: ndt.day}
  end

  @doc """
  Takes a NaiveDateTime struct and returns a Time struct representing the time part
  of the provided NaiveDateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Calendar.NaiveDateTime.to_time
      %Time{microsecond: {0, 0}, hour: 2, minute: 37, second: 22}
  """
  def to_time(ndt) do
    ndt = ndt |> contained_ndt
    %Time{hour: ndt.hour, minute: ndt.minute, second: ndt.second, microsecond: ndt.microsecond}
  end

  @doc """
  For turning NaiveDateTime structs to into a DateTime.

  Takes a NaiveDateTime and a timezone name. If timezone is valid, returns a tuple with an :ok and DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Calendar.NaiveDateTime.to_date_time("UTC")
      {:ok, %DateTime{zone_abbr: "UTC", day: 15, microsecond: {0, 0}, hour: 2, minute: 37, month: 10, second: 22, std_offset: 0, time_zone: "UTC", utc_offset: 0, year: 2014}}
  """
  def to_date_time(ndt, timezone) do
    ndt = ndt |> contained_ndt
    Calendar.DateTime.from_erl(to_erl(ndt), timezone, ndt.microsecond)
  end

  @doc """
  Promote to DateTime with UTC time zone. Should only be used if you
  are sure that the provided argument is in UTC.

  Takes a NaiveDateTime. Returns a DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Calendar.NaiveDateTime.to_date_time_utc
      %DateTime{zone_abbr: "UTC", day: 15, microsecond: {0, 0}, hour: 2, minute: 37, month: 10, second: 22, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2014}
  """
  def to_date_time_utc(ndt) do
    ndt = ndt |> contained_ndt
    {:ok, dt} = to_date_time(ndt, "Etc/UTC")
    dt
  end

  @doc """
  Create new NaiveDateTime struct based on a date and a time.

  ## Examples

      iex> from_date_and_time({2016, 1, 8}, {14, 10, 55})
      {:ok, %NaiveDateTime{day: 8, microsecond: {0, 0}, hour: 14, minute: 10, month: 1, second: 55, year: 2016}}
      iex> from_date_and_time(Calendar.Date.Parse.iso8601!("2016-01-08"), {14, 10, 55})
      {:ok, %NaiveDateTime{day: 8, microsecond: {0, 0}, hour: 14, minute: 10, month: 1, second: 55, year: 2016}}
  """
  def from_date_and_time(date_container, time_container) do
    contained_time = Calendar.ContainsTime.time_struct(time_container)
    from_erl({Calendar.Date.to_erl(date_container), Calendar.Time.to_erl(contained_time)}, contained_time.microsecond)
  end

  @doc """
  Like `from_date_and_time/2` but returns the result untagged.
  Raises in case of an error.

  ## Example

      iex> from_date_and_time!({2016, 1, 8}, {14, 10, 55})
      %NaiveDateTime{day: 8, microsecond: {0, 0}, hour: 14, minute: 10, month: 1, second: 55, year: 2016}
  """
  def from_date_and_time!(date_container, time_container) do
    {:ok, result} = from_date_and_time(date_container, time_container)
    result
  end

  @doc """
  If you have a naive datetime and you know the offset, promote it to a
  UTC DateTime.

  ## Examples

      # A naive datetime at 2:37:22 with a 3600 second offset will return
      # a UTC DateTime with the same date, but at 1:37:22
      iex> with_offset_to_datetime_utc {{2014,10,15},{2,37,22}}, 3600
      {:ok, %DateTime{zone_abbr: "UTC", day: 15, microsecond: {0, 0}, hour: 1, minute: 37, month: 10, second: 22, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2014} }
      iex> with_offset_to_datetime_utc{{2014,10,15},{2,37,22}}, 999_999_999_999_999_999_999_999_999
      {:error, nil}
  """
  def with_offset_to_datetime_utc(ndt, total_utc_offset) do
    ndt = ndt |> contained_ndt
    {tag, advanced_ndt} = ndt |> advance(total_utc_offset*-1)
    case tag do
      :ok -> to_date_time(advanced_ndt, "Etc/UTC")
      _ -> {:error, nil}
    end
  end

  @doc """
  Takes a NaiveDateTime and an integer.
  Returns the `naive_date_time` advanced by the number
  of seconds found in the `seconds` argument.

  If `seconds` is negative, the time is moved back.

  ## Examples

      # Advance 2 seconds
      iex> from_erl!({{2014,10,2},{0,29,10}}, 123456) |> add(2)
      {:ok, %NaiveDateTime{day: 2, hour: 0, minute: 29, month: 10,
            second: 12, microsecond: {123456, 6},
            year: 2014}}
  """
  def add(ndt, seconds),  do: advance(ndt, seconds)

  @doc """
  Like `add` without exclamation points.
  Instead of returning a tuple with :ok and the result,
  the result is returned untagged. Will raise an error in case
  no correct result can be found based on the arguments.

  ## Examples

      # Advance 2 seconds
      iex> from_erl!({{2014,10,2},{0,29,10}}, 123456) |> add!(2)
      %NaiveDateTime{day: 2, hour: 0, minute: 29, month: 10,
            second: 12, microsecond: {123456, 6},
            year: 2014}
  """
  def add!(ndt, seconds), do: advance!(ndt, seconds)

  def subtract(ndt, seconds),  do: add(ndt, -1 * seconds)
  def subtract!(ndt, seconds), do: add!(ndt, -1 * seconds)

  @doc """
  Deprecated version of `add/2`
  """
  def advance(ndt, seconds) do
    try do
      ndt = ndt |> contained_ndt
      greg_secs = ndt |> gregorian_seconds
      advanced = greg_secs + seconds
      |>from_gregorian_seconds!(ndt.microsecond)
      {:ok, advanced}
    rescue
      FunctionClauseError ->
      {:error, :function_clause_error}
    end
  end

  @doc """
  Deprecated version of `add!/2`
  """
  def advance!(ndt, seconds) do
    ndt = ndt |> contained_ndt
    {:ok, result} = advance(ndt, seconds)
    result
  end

  @doc """
  Takes a NaiveDateTime and returns an integer of gregorian seconds starting with
  year 0. This is done via the Erlang calendar module.

  ## Examples

      iex> from_erl!({{2014,9,26},{17,10,20}}) |> gregorian_seconds
      63578970620
  """
  def gregorian_seconds(ndt) do
    ndt
    |> contained_ndt
    |> to_erl
    |> :calendar.datetime_to_gregorian_seconds
  end

  @doc """
  The difference between two naive datetimes. In seconds and microseconds.

  Returns tuple with {:ok, seconds, microseconds, :before or :after or :same_time}

  If the first argument is later (e.g. greater) the second, the result will be positive.

  In case of a negative result the second element (seconds) will be negative. This is always
  the case if both of the arguments have the microseconds as nil or 0. But if the difference
  is less than a second and the result is negative, then the microseconds will be negative.

  ## Examples

      # The first NaiveDateTime is 40 seconds after the second NaiveDateTime
      iex> diff({{2014,10,2},{0,29,50}}, {{2014,10,2},{0,29,10}})
      {:ok, 40, 0, :after}
      # The first NaiveDateTime is 40 seconds before the second NaiveDateTime
      iex> diff({{2014,10,2},{0,29,10}}, {{2014,10,2},{0,29,50}})
      {:ok, -40, 0, :before}
      iex> diff(from_erl!({{2014,10,2},{0,29,10}},{999999, 6}), from_erl!({{2014,10,2},{0,29,50}}))
      {:ok, -39, 1, :before}
      iex> diff(from_erl!({{2014,10,2},{0,29,10}},{999999, 6}), from_erl!({{2014,10,2},{0,29,11}}))
      {:ok, 0, -1, :before}
      iex> diff(from_erl!({{2014,10,2},{0,29,11}}), from_erl!({{2014,10,2},{0,29,10}},{999999, 6}))
      {:ok, 0, 1, :after}
      iex> diff(from_erl!({{2014,10,2},{0,29,11}}), from_erl!({{2014,10,2},{0,29,11}}))
      {:ok, 0, 0, :same_time}
  """
  def diff(%NaiveDateTime{} = first_dt, %NaiveDateTime{} = second_dt) do
    first_dt_utc  = first_dt  |> to_date_time_utc
    second_dt_utc = second_dt |> to_date_time_utc
    Calendar.DateTime.diff(first_dt_utc, second_dt_utc)
  end
  def diff(ndt1, ndt2) do
    diff(contained_ndt(ndt1), contained_ndt(ndt2))
  end

  @doc """
  Takes a two `NaiveDateTime`s and returns true if the first
  one is greater than the second. Otherwise false. Greater than
  means that it is later then the second datetime.

  ## Examples

      iex> {{2014,1,1}, {10,10,10}} |> after?({{1999, 1, 1}, {11, 11, 11}})
      true
      iex> {{2014,1,1}, {10,10,10}} |> after?({{2020, 1, 1}, {11, 11, 11}})
      false
      iex> {{2014,1,1}, {10,10,10}} |> after?({{2014, 1, 1}, {10, 10, 10}})
      false
  """
  def after?(ndt1, ndt2) do
    {_, _, _, comparison} = diff(ndt1, ndt2)
    comparison == :after
  end

  @doc """
  Takes a two `NaiveDateTime`s and returns true if the first
  one is less than the second. Otherwise false. Less than
  means that it is earlier then the second datetime.

  ## Examples

      iex> {{2014,1,1}, {10,10,10}} |> before?({{1999, 1, 1}, {11, 11, 11}})
      false
      iex> {{2014,1,1}, {10,10,10}} |> before?({{2020, 1, 1}, {11, 11, 11}})
      true
      iex> {{2014,1,1}, {10,10,10}} |> before?({{2014, 1, 1}, {10, 10, 10}})
      false
  """
  def before?(ndt1, ndt2) do
    {_, _, _, comparison} = diff(ndt1, ndt2)
    comparison == :before
  end
  @doc """
  Takes a two `NaiveDateTime`s and returns true if the first
  is equal to the second one.

  In this context equal means that they happen at the same time.

  ## Examples

      iex> {{2014,1,1}, {10,10,10}} |> same_time?({{1999, 1, 1}, {11, 11, 11}})
      false
      iex> {{2014,1,1}, {10,10,10}} |> same_time?({{2020, 1, 1}, {11, 11, 11}})
      false
      iex> {{2014,1,1}, {10,10,10}} |> same_time?({{2014, 1, 1}, {10, 10, 10}})
      true
  """
  def same_time?(ndt1, ndt2) do
    {_, _, _, comparison} = diff(ndt1, ndt2)
    comparison == :same_time
  end

  defp from_gregorian_seconds!(gregorian_seconds, microsecond) do
    gregorian_seconds
    |>:calendar.gregorian_seconds_to_datetime
    |>from_erl!(microsecond)
  end

  defp contained_ndt(ndt_container) do
    Calendar.ContainsNaiveDateTime.ndt_struct(ndt_container)
  end
end

defimpl Calendar.ContainsNaiveDateTime, for: NaiveDateTime do
  def ndt_struct(data), do: data
end

defimpl Calendar.ContainsNaiveDateTime, for: Calendar.DateTime do
  def ndt_struct(data), do: data |> Calendar.DateTime.to_naive
end

defimpl Calendar.ContainsNaiveDateTime, for: Tuple do
  def ndt_struct({{year, month, day}, {hour, min, sec}}) do
    NaiveDateTime.from_erl!({{year, month, day}, {hour, min, sec}})
  end
  def ndt_struct({{year, month, day}, {hour, min, sec, microsecond}}) do
    Calendar.NaiveDateTime.from_erl!({{year, month, day}, {hour, min, sec}}, microsecond)
  end
end

defimpl Calendar.ContainsNaiveDateTime, for: DateTime do
  def ndt_struct(%{calendar: Calendar.ISO}=data), do: %NaiveDateTime{day: data.day, month: data.month, year: data.year, hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond}
end
#defimpl Calendar.ContainsNaiveDateTime, for: NaiveDateTime do
#  def ndt_struct(%{calendar: Calendar.ISO}=data), do: %NaiveDateTime{day: data.day, month: data.month, year: data.year, hour: data.hour, minute: data.minute, second: data.second, microsecond: data.microsecond}
#end
