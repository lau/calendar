defmodule Calendar.Mixfile do
  use Mix.Project

  def project do
    [app: :calendar,
     name: "Calendar",
     version: "0.17.2",
     elixir: "~> 1.4.0 or ~> 1.4.0-dev or ~> 1.3.0 or ~> 1.3.0-rc.1",
     consolidate_protocols: false,
     package: package(),
     description: description(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  def deps do
    [
      {:tzdata, "~> 0.5.8 or ~> 0.1.201603"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, only: :docs},
     ]
  end

  defp package do
    %{ licenses: ["MIT"],
       maintainers: ["Lau Taarnskov"],
       links: %{ "GitHub" => "https://github.com/lau/calendar"},
       files: ~w(lib priv mix.exs README* LICENSE*
                    CHANGELOG*) }
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
