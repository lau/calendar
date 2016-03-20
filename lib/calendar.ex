defmodule Calendar do
  @moduledoc File.read!("README.md")

  @doc false
  defmacro __using__(_opts) do
     %{file: file, line: line} = __CALLER__
     :elixir_errors.warn(line, file, "use Calendar is deprecated")
    quote do
      alias Calendar.DateTime
      alias Calendar.DateTime.Interval
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
