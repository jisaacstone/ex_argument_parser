defmodule ArgumentParser.Mixfile do
  use Mix.Project

  def project do
    [app: :argument_parser,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  def deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc,  "~> 0.8", only: :dev}]
  end
end
