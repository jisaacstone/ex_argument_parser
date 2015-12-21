defmodule ArgumentParser.Mixfile do
  use Mix.Project

  def project do
    [app: :argument_parser,
     version: "0.0.2",
     elixir: "~> 1.1-dev",
     name: "ArgumentParserEx",
     source_url: "https://github.com/jisaacstone/ex_argument_parser",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    []
  end

  def deps do
    [ {:dialyze, "~> 0.2"} ]
  end
end
