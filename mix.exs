defmodule ArgumentParser.Mixfile do
  use Mix.Project

  def project do
    [app: :argument_parser,
     version: "0.0.2",
     elixir: "~> 1.1-dev",
     package: package,
     name: "ArgumentParserEx",
     source_url: "https://github.com/jisaacstone/ex_argument_parser",
     deps: deps]
  end

  def application do
    []
  end

  defp package do
   [licenses: ["Apache 2.0"],
    links: %{"GitHub" => "https://github.com/jisaacstone/ex_argument_parser"}]
  end

  def deps do
    [ {:dialyze, "~> 0.2", only: :dev},
      {:readme_md_doc, "~> 0.1", only: :dev} ]
  end
end
