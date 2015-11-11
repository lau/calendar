defmodule Calendar.Interval do
@moduledoc """
An `Interval` consists of a start and an end `DateTime`.
"""

  defstruct [:from, :to]
  use Calendar

  @doc """
  Returns true when the interval contains the given datetime.
  """
  def includes?(%Interval{from: from, to: to}, datetime) do
    DateTime.before?(from, datetime) && DateTime.after?(to, datetime)
  end
end
