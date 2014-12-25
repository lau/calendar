defmodule Kalends do
  @moduledoc File.read!("README.md")

  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Kalends.DateTime
      alias Kalends.AmbiguousDateTime
      alias Kalends.NaiveDateTime
      alias Kalends.Date
      alias Kalends.Time
      alias Kalends.TimeZoneData
      alias Kalends.TimeZonePeriods
    end
  end
end
