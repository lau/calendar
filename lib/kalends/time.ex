defmodule Kalends.Time do
  defstruct [:hour, :min, :sec, :frac_sec]

  def to_erl(%Kalends.Time{hour: hour, min: min, sec: sec}) do
    {hour, min, sec}
  end
end
