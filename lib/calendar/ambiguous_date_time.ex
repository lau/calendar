defmodule Calendar.AmbiguousDateTime do
  @moduledoc """
  AmbiguousDateTime provides a struct which represents an ambiguous time and
  date in a certain time zone. These structs will be returned from the
  DateTime.from_erl/2 function when the provided time is ambiguous.

  AmbiguousDateTime contains two DateTime structs. For instance they can
  represent both a DST and non-DST time. If clocks are turned back an hour
  at 2:00 when going from summer to winter time then the "wall time" between
  1:00 and 2:00 happens twice. One of them is on DST and one of them is not.

  The provided functions can be used to choose one of the two DateTime structs.
  """
  defstruct [:possible_date_times]

  @doc """
  Disambiguate an AmbiguousDateTime by total offset. Total offset would be UTC
  offset plus standard offset.

  If only one of the possible data times contained in the ambiguous_date_time
  matches the offset a tuple with :ok and the matching DateTime is returned.

  ## Total offset

  For instance, at the time of this writing, for Berlin there is a 1 hour UTC
  offset. In the summer, there is another hour of standard offset. This means
  that in the summer the total offset is 2 hours or 7200 seconds.

  ## Examples

      iex> {:ambiguous, am} = Calendar.DateTime.from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo"); am |> Calendar.AmbiguousDateTime.disamb_total_off(-10800)
      {:ok, %DateTime{zone_abbr: "-03", day: 9, hour: 1, minute: 1, month: 3, second: 1, std_offset: 0, time_zone: "America/Montevideo", utc_offset: -10800, year: 2014, microsecond: {0,0}}}

      iex> {:ambiguous, am} = Calendar.DateTime.from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo"); am |> Calendar.AmbiguousDateTime.disamb_total_off(0)
      {:error, :no_matches}
  """
  def disamb_total_off(ambiguous_date_time, total_off_secs) do
    func = fn(dt) -> dt.utc_offset+dt.std_offset == total_off_secs end
    disamb(ambiguous_date_time, func)
  end

  @doc """
  Disambiguate an AmbiguousDateTime according to filtering function provided
  as the second parameter

  ## Examples

  We provide a function that returns true if the abbreviation is "-03"

      iex> {:ambiguous, am} = Calendar.DateTime.from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo"); am |> Calendar.AmbiguousDateTime.disamb(fn(dt) -> dt.zone_abbr == "-03" end)
      {:ok, %DateTime{zone_abbr: "-03", day: 9, hour: 1, minute: 1, month: 3, second: 1, std_offset: 0, time_zone: "America/Montevideo", utc_offset: -10800, year: 2014, microsecond: {0, 0}}}

  A function that always returns false

      iex> {:ambiguous, am} = Calendar.DateTime.from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo"); am |> Calendar.AmbiguousDateTime.disamb(fn(_dt) -> false end)
      {:error, :no_matches}

  A function that always returns true

      iex> {:ambiguous, am} = Calendar.DateTime.from_erl({{2014, 3, 9}, {1, 1, 1}}, "America/Montevideo"); am |> Calendar.AmbiguousDateTime.disamb(fn(_dt) -> true end)
      {:error, :more_than_one_match}
  """
  def disamb(ambiguous_date_time, filtering_func) do
    matching = ambiguous_date_time.possible_date_times
    |> Enum.filter(filtering_func)
    disamb_matching_date_times(matching, length(matching))
  end

  defp disamb_matching_date_times(date_times, 1) do
    {:ok, hd(date_times)}
  end
  defp disamb_matching_date_times(_, 0) do
    {:error, :no_matches}
  end
  defp disamb_matching_date_times(_, match_count) when match_count > 1 do
    {:error, :more_than_one_match}
  end
end
