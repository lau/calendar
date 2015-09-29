defprotocol Calendar.ContainsDate do
  @doc """
  Returns a Calendar.Date struct for the struct in question
  """
  def date_struct(data)
end

defmodule Calendar.Date do
  alias Calendar.NaiveDateTime
  alias Calendar.ContainsDate

  @moduledoc """
  The Date module provides a struct to represent a simple date: year, month and day.
  """

  defstruct [:year, :month, :day]

  @doc """
  Takes a Date struct and returns an erlang style date tuple.
  """
  def to_erl(date) do
    date = date |> contained_date
    {date.year, date.month, date.day}
  end

  @doc """
  Takes a erlang style date tuple and returns a tuple with an :ok tag and a
  Date struct. If the provided date is invalid, it will not be tagged with :ok
  though as shown below:

      iex> from_erl({2014,12,27})
      {:ok, %Calendar.Date{day: 27, month: 12, year: 2014}}

      iex> from_erl({2014,99,99})
      {:error, :invalid_date}
  """
  def from_erl({year, month, day}) do
    if :calendar.valid_date({year, month, day}) do
      {:ok, %Calendar.Date{year: year, month: month, day: day}}
    else
      {:error, :invalid_date}
    end
  end

  @doc """
  Like from_erl without the exclamation point, but does not return a tuple
  with a tag. Instead returns just a Date if valid. Or raises an exception if
  the provided date is invalid.

      iex> from_erl! {2014,12,27}
      %Calendar.Date{day: 27, month: 12, year: 2014}
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
    date = date |> contained_date
    {year, month, _} = ContainsDate.date_struct(date) |> to_erl
    :calendar.last_day_of_the_month(year, month)
  end

  @doc """
  Takes a Date struct and returns a tuple with the ISO week number
  and the year that the week belongs to.
  Note that the year returned is not always the same as the year provided
  as an argument.

      iex> from_erl!({2014,12,31}) |> week_number
      {2015, 1}
      iex> from_erl!({2014,12,27}) |> week_number
      {2014, 52}
  """
  def week_number(date) do
    date = date |> contained_date
    :calendar.iso_week_number(date|>to_erl)
  end

  @doc """
  Takes a year and an ISO week number and returns a list with the dates in that week.

      iex> dates_for_week_number(2015, 1)
      [%Calendar.Date{day: 29, month: 12, year: 2014}, %Calendar.Date{day: 30, month: 12, year: 2014},
            %Calendar.Date{day: 31, month: 12, year: 2014}, %Calendar.Date{day: 1, month: 1, year: 2015},
            %Calendar.Date{day: 2, month: 1, year: 2015}, %Calendar.Date{day: 3, month: 1, year: 2015},
            %Calendar.Date{day: 4, month: 1, year: 2015}]
      iex> dates_for_week_number(2015, 2)
      [%Calendar.Date{day: 5, month: 1, year: 2015}, %Calendar.Date{day: 6, month: 1, year: 2015},
            %Calendar.Date{day: 7, month: 1, year: 2015}, %Calendar.Date{day: 8, month: 1, year: 2015},
            %Calendar.Date{day: 9, month: 1, year: 2015}, %Calendar.Date{day: 10, month: 1, year: 2015},
            %Calendar.Date{day: 11, month: 1, year: 2015}]
  """
  def dates_for_week_number(year, week_num) do
    days_after_until(from_erl!({year-1, 12, 23}), from_erl!({year, 12, 31}))
    |> Enum.filter fn(x) -> in_week?(x, year, week_num) end
  end
  @doc "Like dates_for_week_number/2 but takes a tuple of {year, week_num} instead"
  def dates_for_week_number({year, week_num}), do: dates_for_week_number(year, week_num)

  @doc """
  Takes a date, a year and an ISO week number and returns true if the date is in
  the week.

      iex> {2015, 1, 1} |> in_week? 2015, 1
      true
      iex> {2015, 5, 5} |> in_week? 2015, 1
      false
  """
  def in_week?(date, year, week_num) do
    date |> week_number == {year, week_num}
  end

  @doc """
  Takes a Date struct and returns the number of gregorian days since year 0.

      iex> from_erl!({2014,12,27}) |> to_gregorian_days
      735959
  """
  def to_gregorian_days(date) do
    date = date |> contained_date
    :calendar.date_to_gregorian_days(date.year, date.month, date.day)
  end

  defp from_gregorian_days!(days) do
    :calendar.gregorian_days_to_date(days) |> from_erl!
  end

  @doc """
  Takes a Date struct and returns another one representing the next day.

      iex> from_erl!({2014,12,27}) |> next_day!
      %Calendar.Date{day: 28, month: 12, year: 2014}
      iex> from_erl!({2014,12,31}) |> next_day!
      %Calendar.Date{day: 1, month: 1, year: 2015}
  """
  def next_day!(date) do
    advance!(date, 1)
  end

  @doc """
  Takes a Date struct and returns another one representing the previous day.

      iex> from_erl!({2014,12,27}) |> prev_day!
      %Calendar.Date{day: 26, month: 12, year: 2014}
  """
  def prev_day!(date) do
    advance!(date, -1)
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
  def diff(first_date_cont, second_date_cont) do
    first_date = contained_date(first_date_cont)
    second_date = contained_date(second_date_cont)
    to_gregorian_days(first_date) - to_gregorian_days(second_date)
  end

  @doc """
  Advances `date` by `days` number of days.

  ## Examples

      # Date struct advanced by 3 days
      iex> from_erl!({2014,12,27}) |> advance(3)
      {:ok, %Calendar.Date{day: 30, month: 12, year: 2014} }
      # Date struct turned back 2 days
      iex> from_erl!({2014,12,27}) |> advance(-2)
      {:ok, %Calendar.Date{day: 25, month: 12, year: 2014} }
      # Date tuple turned back 2 days
      iex> {2014,12,27} |> advance(-2)
      {:ok, %Calendar.Date{day: 25, month: 12, year: 2014} }
      # When passing a DateTime, NaiveDateTime or datetime tuple
      # the time part is ignored. A Date struct is returned.
      iex> {{2014,12,27}, {21,30,59}} |> NaiveDateTime.from_erl! |> advance(-2)
      {:ok, %Calendar.Date{day: 25, month: 12, year: 2014} }
      iex> {{2014,12,27}, {21,30,59}} |> advance(-2)
      {:ok, %Calendar.Date{day: 25, month: 12, year: 2014} }
  """
  def advance(date, days) when is_integer(days) do
    date = date |> contained_date
    result = to_gregorian_days(date) + days
    |> from_gregorian_days!
    {:ok, result}
  end

  @doc """
  Like `advance/2`, but returns the result directly - not tagged with :ok.
  This function might raise an error.

  ## Examples

      iex> from_erl!({2014,12,27}) |> advance!(3)
      %Calendar.Date{day: 30, month: 12, year: 2014}
      iex> {2014,12,27} |> advance!(-2)
      %Calendar.Date{day: 25, month: 12, year: 2014}
  """
  def advance!(date, days) when is_integer(days) do
    date = date |> contained_date
    {:ok, result} = advance(date, days)
    result
  end

  @doc """
  DEPRICATED. Use `Calendar.Strftime.strftime!/3` instead - it works the same way.
  """
  def strftime!(date, string, lang \\ :en) do
    IO.puts :stderr, "Warning: strftime!/1 in Calendar.Date is deprecated." <>
                     "The function has been moved so use Calendar.Strftime.strftime! instead. " <>
                     Exception.format_stacktrace()
    date = contained_date(date)
    date_erl = date |> to_erl
    {date_erl, {0, 0, 0}}
    |> NaiveDateTime.from_erl!
    |> Calendar.Strftime.strftime! string, lang
  end

  @doc """
  Stream of dates after the date provided as argument.

      iex> days_after({2014,12,27}) |> Enum.take(6)
      [%Calendar.Date{day: 28, month: 12, year: 2014}, %Calendar.Date{day: 29, month: 12, year: 2014},
            %Calendar.Date{day: 30, month: 12, year: 2014}, %Calendar.Date{day: 31, month: 12, year: 2014}, %Calendar.Date{day: 1, month: 1, year: 2015},
            %Calendar.Date{day: 2, month: 1, year: 2015}]
  """
  def days_after(from_date) do
    from_date = from_date |> contained_date
    Stream.unfold(next_day!(from_date), fn n -> {n, n |> next_day!} end)
  end

  @doc """
  Stream of dates before the date provided as argument.

      iex> days_before(from_erl!({2014,12,27})) |> Enum.take(3)
      [%Calendar.Date{day: 26, month: 12, year: 2014}, %Calendar.Date{day: 25, month: 12, year: 2014},
            %Calendar.Date{day: 24, month: 12, year: 2014}]
  """
  def days_before(from_date) do
    from_date = from_date |> contained_date
    Stream.unfold(prev_day!(from_date), fn n -> {n, n |> prev_day!} end)
  end

  @doc """
  Get a stream of dates. Takes a starting date and an end date. Includes end date.
  Does not include start date.

      iex> days_after_until(from_erl!({2014,12,27}), from_erl!({2014,12,29})) |> Enum.to_list
      [%Calendar.Date{day: 28, month: 12, year: 2014}, %Calendar.Date{day: 29, month: 12, year: 2014}]
  """
  def days_after_until(from_date, until_date) do
    from_date = from_date |> contained_date
    until_date = until_date |> contained_date
    Stream.unfold(next_day!(from_date), fn n -> if n == next_day!(until_date) do nil else {n, n |> next_day!} end end)
  end

  @doc """
  Get a stream of dates going back in time. Takes a starting date and an end date. Includes end date.
  End date should be before start date.
  Does not include start date.

      iex> days_before_until(from_erl!({2014,12,27}), from_erl!({2014,12,24})) |> Enum.to_list
      [%Calendar.Date{day: 26, month: 12, year: 2014}, %Calendar.Date{day: 25, month: 12, year: 2014}, %Calendar.Date{day: 24, month: 12, year: 2014}]
  """
  def days_before_until(from_date, until_date) do
    Stream.unfold(prev_day!(from_date), fn n -> if n == prev_day!(until_date) do nil else {n, n |> prev_day!} end end)
  end

  @doc """
  Day of the week as an integer. Monday is 1, Tuesday is 2 and so on.
  ISO-8601. Sunday is 7.
  Results can be between 1 and 7.

  See also `day_of_week_zb/1`

  ## Examples

      iex> {2015, 7, 6} |> day_of_week # Monday
      1
      iex> {2015, 7, 7} |> day_of_week # Tuesday
      2
      iex> {2015, 7, 5} |> day_of_week # Sunday
      7
  """
  def day_of_week(date) do
    date = date |> contained_date
    date |> to_erl |> :calendar.day_of_the_week
  end

  @doc """
  The name of the day of the week as a string.
  Takes a language code as the second argument. Defaults to :en for English.

  ## Examples

      iex> {2015, 7, 6} |> day_of_week_name # Monday
      "Monday"
      iex> {2015, 7, 7} |> day_of_week_name # Tuesday
      "Tuesday"
      iex> {2015, 7, 5} |> day_of_week_name # Sunday
      "Sunday"
  """
  def day_of_week_name(date, lang\\:en) do
    date = date |> contained_date
    date |> Calendar.Strftime.strftime!("%A", lang)
  end

  @doc """
  Day of the week as an integer with Sunday being 0.
  Monday is 1, Tuesday is 2 and so on. Results can be
  between 0 and 6.

  ## Examples

      iex> {2015, 7, 5} |> day_of_week_zb # Sunday
      0
      iex> {2015, 7, 6} |> day_of_week_zb # Monday
      1
      iex> {2015, 7, 7} |> day_of_week_zb # Tuesday
      2
  """
  def day_of_week_zb(date) do
    num = date |> day_of_week
    case num do
      7 -> 0
      _ -> num
    end
  end

  @doc """
  Day number in year for provided `date`.

  ## Examples

      iex> {2015, 1, 1} |> day_number_in_year
      1
      iex> {2015, 2, 1} |> day_number_in_year
      32
      # 2015 has 365 days
      iex> {2015, 12, 31} |> day_number_in_year
      365
      # 2000 was leap year and had 366 days
      iex> {2000, 12, 31} |> day_number_in_year
      366
  """
  def day_number_in_year(date) do
    date = date |> contained_date
    day_count_previous_months = Enum.map(previous_months_for_month(date.month),
      fn month ->
        :calendar.last_day_of_the_month(date.year, month)
      end)
    |> Enum.reduce(0, fn(day_count, acc) -> day_count + acc end)
    day_count_previous_months+date.day
  end
  # a list or range of previous month names
  defp previous_months_for_month(1), do: []
  defp previous_months_for_month(month) do
    1..(month-1)
  end

  @doc """
  Returns `true` if the `date` is a Monday.

  ## Examples

      iex> {2015, 7, 6} |> monday?
      true
      iex> {2015, 7, 7} |> monday?
      false
  """
  def monday?(date), do: day_of_week(date) == 1

  @doc """
  Returns `true` if the `date` is a Tuesday.

  ## Examples

      iex> {2015, 7, 6} |> tuesday?
      false
      iex> {2015, 7, 7} |> tuesday?
      true
  """
  def tuesday?(date), do: day_of_week(date) == 2

  @doc """
  Returns `true` if the `date` is a Wednesday.

  ## Examples

      iex> {2015, 7, 8} |> wednesday?
      true
      iex> {2015, 7, 9} |> wednesday?
      false
  """
  def wednesday?(date), do: day_of_week(date) == 3

  @doc """
  Returns `true` if the `date` is a Thursday.

  ## Examples

      iex> {2015, 7, 9} |> thursday?
      true
      iex> {2015, 7, 7} |> thursday?
      false
  """
  def thursday?(date), do: day_of_week(date) == 4

  @doc """
  Returns `true` if the `date` is a Friday.

  ## Examples

      iex> {2015, 7, 10} |> friday?
      true
      iex> {2015, 7, 7} |> friday?
      false
  """
  def friday?(date), do: day_of_week(date) == 5

  @doc """
  Returns `true` if the `date` is a Saturday.

  ## Examples

      iex> {2015, 7, 11} |> saturday?
      true
      iex> {2015, 7, 7} |> saturday?
      false
  """
  def saturday?(date), do: day_of_week(date) == 6

  @doc """
  Returns `true` if the `date` is a Sunday.

  ## Examples

      iex> {2015, 7, 12} |> sunday?
      true
      iex> {2015, 7, 7} |> sunday?
      false
  """
  def sunday?(date), do: day_of_week(date) == 7

  defp contained_date(date_container), do: ContainsDate.date_struct(date_container)
end

defimpl Calendar.ContainsDate, for: Calendar.Date do
  def date_struct(data), do: data
end
defimpl Calendar.ContainsDate, for: Calendar.DateTime do
  def date_struct(data) do
    data |> Calendar.DateTime.to_date
  end
end
defimpl Calendar.ContainsDate, for: Calendar.NaiveDateTime do
  def date_struct(data) do
    data |> Calendar.NaiveDateTime.to_date
  end
end
defimpl Calendar.ContainsDate, for: Tuple do
  def date_struct({y, m, d}), do: Calendar.Date.from_erl!({y, m, d})
  def date_struct({{y, m, d}, {_hour, _min, _sec}}), do: Calendar.Date.from_erl!({y, m, d})
  def date_struct({{y, m, d}, {_hour, _min, _sec, _usec}}), do: Calendar.Date.from_erl!({y, m, d})
end
