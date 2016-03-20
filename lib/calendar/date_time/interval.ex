defmodule Calendar.DateTime.Interval do
@moduledoc """
An `Interval` consists of a start and an end `DateTime`.
"""

  @type t :: %__MODULE__{from: %Calendar.DateTime{}, to: %Calendar.DateTime{}}

  defstruct [:from, :to]

  @doc """
  Returns `true` when the interval contains the given datetime.

  "From" and "to" datetimes are treated as inclusive. This means that if the
  provided `datetime` is between the `from` and `to` of the interval or equal
  to either, `true` will be returned.
  """
  @spec includes?(t, %Calendar.DateTime{}) :: boolean
  def includes?(%Calendar.DateTime.Interval{from: from, to: to}, datetime) do
    !Calendar.DateTime.before?(datetime, from) && !Calendar.DateTime.after?(datetime, to)
  end
end
