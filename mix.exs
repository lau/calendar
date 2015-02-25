defmodule Kalends.Mixfile do
  use Mix.Project

  def project do
    [app: :kalends,
     name: "Kalends",
     version: "0.2.6",
     elixir: "~> 1.1.0 or ~> 1.0.0 or ~> 0.15.1",
     package: package,
     description: description,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  def deps do
    [{:ex_doc, "~> 0.6", only: :dev},
     ]
  end

  defp package do
    %{ licenses: ["MIT"],
       contributors: ["Lau Taarnskov"],
       links: %{ "GitHub" => "https://github.com/lau/kalends"},
       files: ~w(lib priv mix.exs README* LICENSE*
                    license* CHANGELOG* changelog* src tzdata) }
  end

  defp description do
    """
    Kalends is a datetime library in pure Elixir with up-to-date timezone
    support using the Olson database.
    """
  end
end
