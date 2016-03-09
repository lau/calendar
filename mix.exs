defmodule Calendar.Mixfile do
  use Mix.Project

  def project do
    [app: :calendar,
     name: "Calendar",
     version: "0.13.2",
     elixir: "~> 1.2.0 or ~> 1.1.0 or ~> 1.0.0",
     consolidate_protocols: false,
     package: package,
     description: description,
     deps: deps]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  def deps do
    [
      {:tzdata, "~> 0.5.6 or ~> 0.1.201601"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, only: :docs},
     ]
  end

  defp package do
    %{ licenses: ["MIT"],
       maintainers: ["Lau Taarnskov"],
       links: %{ "GitHub" => "https://github.com/lau/calendar"},
       files: ~w(lib priv mix.exs README* LICENSE*
                    license* CHANGELOG* changelog* src tzdata) }
  end

  defp description do
    """
    Calendar is a datetime library for Elixir.

    Providing explicit types for datetimes, dates and times.
    Full timezone support via its sister package `tzdata`.

    Safe parsing and formatting of standard formats (ISO, RFC, Unix, JS etc.)
    plus strftime formatting. Easy and safe interoperability with erlang style
    datetime tuples. Extendable through protocols.

    Related packages are available for i18n, Ecto and Phoenix interoperability.
    """
  end
end
