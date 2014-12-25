defmodule Kalends.Date do
  defstruct [:year, :month, :day]

  def to_erl(%Kalends.Date{year: year, month: month, day: day}) do
    {year, month, day}
  end
end
