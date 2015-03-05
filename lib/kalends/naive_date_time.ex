defmodule Kalends.NaiveDateTime do
  alias Kalends.DateTime
  require Kalends.DateTime.Format

  @moduledoc """
  NaiveDateTime can represents a "naive time". That is a point in time without
  a specified time zone.
  """
  defstruct [:year, :month, :day, :hour, :min, :sec, :usec]

  @doc """
  Like from_erl/1 without "!", but returns the result directly without a tag.
  Will raise if date is invalid. Only use this if you are sure the date is valid.

  ## Examples

      iex> from_erl!({{2014, 9, 26}, {17, 10, 20}})
      %Kalends.NaiveDateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014}

      iex from_erl!({{2014, 99, 99}, {17, 10, 20}})
      # this will throw a MatchError
  """
  def from_erl!(erl_date_time, usec \\ nil) do
    {:ok, result} = from_erl(erl_date_time, usec)
    result
  end

  @doc """
  Takes an Erlang-style date-time tuple.
  If the datetime is valid it returns a tuple with a tag and a naive DateTime.
  Naive in this context means that it does not have any timezone data.

  ## Examples

      iex>from_erl({{2014, 9, 26}, {17, 10, 20}})
      {:ok, %Kalends.NaiveDateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014} }

      iex>from_erl({{2014, 9, 26}, {17, 10, 20}}, 321321)
      {:ok, %Kalends.NaiveDateTime{day: 26, hour: 17, min: 10, month: 9, sec: 20, year: 2014, usec: 321321} }

      iex>from_erl({{2014, 99, 99}, {17, 10, 20}})
      {:error, :invalid_datetime}
  """
  def from_erl({{year, month, day}, {hour, min, sec}}, usec \\ nil) do
    if validate_erl_datetime {{year, month, day}, {hour, min, sec}} do
      {:ok, %Kalends.NaiveDateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec, usec: usec}}
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

  @doc """
  Takes a NaiveDateTime struct and returns a Date struct representing the date part
  of the provided NaiveDateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Kalends.NaiveDateTime.to_date
      %Kalends.Date{day: 15, month: 10, year: 2014}
  """
  def to_date(dt) do
    %Kalends.Date{year: dt.year, month: dt.month, day: dt.day}
  end

  @doc """
  Takes a NaiveDateTime struct and returns a Time struct representing the time part
  of the provided NaiveDateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Kalends.NaiveDateTime.to_time
      %Kalends.Time{usec: nil, hour: 2, min: 37, sec: 22}
  """
  def to_time(dt) do
    %Kalends.Time{hour: dt.hour, min: dt.min, sec: dt.sec, usec: dt.usec}
  end

  @doc """
  For turning NaiveDateTime structs to into a DateTime.

  Takes a NaiveDateTime and a timezone name. If timezone is valid, returns a tuple with an :ok and DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Kalends.NaiveDateTime.to_date_time("UTC")
      {:ok, %Kalends.DateTime{abbr: "UTC", day: 15, usec: nil, hour: 2, min: 37, month: 10, sec: 22, std_off: 0, timezone: "UTC", utc_off: 0, year: 2014}}
  """
  def to_date_time(ndt, timezone) do
    DateTime.from_erl(to_erl(ndt), timezone)
  end

  @doc """
  Promote to DateTime with UTC time zone.

  Takes a NaiveDateTime. Returns a DateTime.

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> Kalends.NaiveDateTime.to_date_time_utc
      %Kalends.DateTime{abbr: "UTC", day: 15, usec: nil, hour: 2, min: 37, month: 10, sec: 22, std_off: 0, timezone: "UTC", utc_off: 0, year: 2014}
  """
  def to_date_time_utc(ndt) do
    {:ok, dt} = to_date_time(ndt, "UTC")
    dt
  end

  @doc """
  Like DateTime.Format.strftime! but for NaiveDateTime.

  Refer to documentation for DateTime.Format.strftime!

      iex> from_erl!({{2014,10,15},{2,37,22}}) |> strftime! "%Y %h %d"
      "2014 Oct 15"
  """
  def strftime!(ndt, string, lang \\ :en) do
    ndt
    |> to_date_time_utc
    |> Kalends.DateTime.Format.strftime! string, lang
  end

end
