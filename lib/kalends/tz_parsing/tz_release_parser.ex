defmodule Kalends.TzParsing.TzReleaseParser do
  # The purpose of this module is to get release version information. E.g. "2014i".
  @moduledoc false

  @file_with_release_version "tzdata/RELEASE_LINE_FROM_NEWS"

  release_string = @file_with_release_version
  |> File.stream!
  |> Enum.to_list |> hd
  |> String.rstrip

  captured = Regex.named_captures( ~r/Release[\s]+(?<version>[^\s]+)[\s]+-[\s]+(?<timestamp>.+)/, release_string)

  # provide release version e.g. "2014i"
  def tzdata_version, do: unquote(Macro.escape(captured["version"]))
end
