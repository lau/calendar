defmodule Calendar do
  @moduledoc File.read!("README.md")

  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Calendar.DateTime
      alias Calendar.AmbiguousDateTime
      alias Calendar.NaiveDateTime
      alias Calendar.Date
      alias Calendar.Time
      alias Calendar.TimeZoneData
      alias Calendar.TzPeriod
      alias Calendar.Strftime
    end
  end
end
