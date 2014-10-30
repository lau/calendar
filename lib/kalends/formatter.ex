defmodule Kalends.Formatter do
  require Kalends.DateTime
  require Kalends.Formatter.Strftime

  @doc """
  Generate a string from a DateTime formatted by a format string. Similar to strftime known from UNIX.

  # Example
      iex> Kalends.DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC")|>Kalends.Formatter.Strftime.strftime "%Y-%m-%e %H:%M:%S"
      "2014-09-6 17:10:20"

      iex> Kalends.DateTime.from_erl!({{2014,9,6},{17,10,20}},"UTC")|>Kalends.Formatter.Strftime.strftime "%d.%m.%y"
      "06.09.14"
  """
  def strftime(dt, string) do
    Kalends.Formatter.Strftime.strftime(dt, string)
  end

  @doc """
  Takes an unambiguous DateTime.
  Returns a string with the time in ISO 8601

  ## Example
    iex> Kalends.DateTime.from_erl!({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo") |> Kalends.Formatter.iso8601
    "2014-09-26T17:10:20-3:00"
  """
  def iso8601(dt) do
    Kalends.Formatter.Strftime.strftime(dt, "%Y-%m-%dT%H:%M:%S")<>
    iso8601_offset_part(dt, dt.timezone)
  end

  defp iso8601_offset_part(_, time_zone) when time_zone == "UTC" or time_zone == "Etc/UTC", do: "Z"
  defp iso8601_offset_part(dt, _) do
    Kalends.Formatter.Strftime.strftime(dt, "%z")
  end
end
