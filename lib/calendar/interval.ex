defmodule Calendar.Interval do
@moduledoc """
An `Interval` consists of a start and an end `DateTime`.
"""

  @type t :: %__MODULE__{from: %Calendar.DateTime{}, to: %Calendar.DateTime{}}

  defstruct [:from, :to]

  use Calendar

  @doc """
  Returns true when the interval contains the given datetime.
  """
  @spec includes?(t, %Calendar.DateTime{}) :: boolean
  def includes?(%Interval{from: from, to: to}, datetime) do
    DateTime.before?(from, datetime) && DateTime.after?(to, datetime)
  end
end
