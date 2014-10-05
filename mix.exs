defmodule Kalends.Mixfile do
  use Mix.Project

  def project do
    [app: :kalends,
     name: "Kalends",
     version: "0.0.1",
     elixir: "~> 1.0.0 or ~> 0.15.1",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  def deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.6", only: :dev}]
  end
end
