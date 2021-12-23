defmodule Calendar.Mixfile do
  use Mix.Project

  @source_url "https://github.com/lau/calendar"
  @version "1.0.0"

  def project do
    [
      app: :calendar,
      name: "Calendar",
      version: @version,
      elixir: "~> 1.4",
      consolidate_protocols: false,
      package: package(),
      description: description(),
      deps: deps(),
      docs: docs(),
    ]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  def deps do
    [
      {:tzdata, "~> 0.5.20 or ~> 0.1.201603 or ~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Lau Taarnskov"],
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*),
      links: %{
        "Changelog" => "https://hexdocs.pm/calendar/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp description do
    """
    Calendar is a datetime library for Elixir.

    Timezone support via its sister package `tzdata`.

    Safe parsing and formatting of standard formats (ISO, RFC, etc.), strftime
    formatting. Extendable through protocols.
    """
  end
end
