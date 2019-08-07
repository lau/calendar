defmodule Calendar.Mixfile do
  use Mix.Project

  def project do
    [
      app: :calendar,
      name: "Calendar",
      version: "0.18.0-dev",
      elixir: "~> 1.4",
      consolidate_protocols: false,
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  def deps do
    [
      {:tzdata, "~> 0.5.20 or ~> 0.1.201603 or ~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Lau Taarnskov"],
      links: %{"GitHub" => "https://github.com/lau/calendar"},
      files: ~w(lib priv mix.exs README* LICENSE*
                    CHANGELOG*)
    }
  end

  defp description do
    """
    Calendar is a datetime library for Elixir.

    Timezone support via its sister package `tzdata`.

    Safe parsing and formatting of standard formats (ISO, RFC, etc.), strftime formatting. Interoperability with erlang style
    datetime tuples. Extendable through protocols.
    """
  end
end
