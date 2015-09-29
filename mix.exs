defmodule Calendar.Mixfile do
  use Mix.Project

  def project do
    [app: :calendar,
     name: "Calendar",
     version: "0.10.1",
     elixir: "~> 1.1.0 or ~> 1.0.0 or ~> 1.1.0-dev",
     package: package,
     description: description,
     deps: deps]
  end

  def application do
    [applications: [:logger, :tzdata]]
  end

  def deps do
    [
      {:tzdata, "~> 0.5.3 or ~> 0.1.7"},
      {:ex_doc, "~> 0.10", only: :dev},
      {:inch_ex, only: :docs},
     ]
  end

  defp package do
    %{ licenses: ["MIT"],
       contributors: ["Lau Taarnskov"],
       links: %{ "GitHub" => "https://github.com/lau/calendar"},
       files: ~w(lib priv mix.exs README* LICENSE*
                    license* CHANGELOG* changelog* src tzdata) }
  end

  defp description do
    """
    Calendar is a datetime library in pure Elixir with up-to-date timezone
    support using the Olson database. Formerly known as Kalends.
    """
  end
end
