defmodule Calendar.Interval do
  defstruct [:begin_datetime, :end_datetime]

  def from(begin_datetime = %Calendar.DateTime{}, end_datetime = %Calendar.DateTime{}) do
    %Calendar.Interval{begin_datetime: begin_datetime, end_datetime: end_datetime}
  end
end
