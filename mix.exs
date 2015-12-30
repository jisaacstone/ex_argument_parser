defmodule ArgumentParser.Mixfile do
  use Mix.Project

  def project do
    [app: :argument_parser,
     version: "0.1.2",
     elixir: "~> 1.1",
     package: package,
     name: "ArgumentParser",
     source_url: "https://github.com/jisaacstone/ex_argument_parser",
     description: "More powerful argument parser for creating nice scripts",
     deps: deps]
  end

  def application do
    []
  end

  defp package do
   [ licenses: ["Apache 2.0"],
     maintainers: ["jisaacstone"],
     links: %{"GitHub" => "https://github.com/jisaacstone/ex_argument_parser"} ]
  end

  def deps do
    [ {:dialyze, "~> 0.2", only: :dev},
      {:readme_md_doc, "~> 0.1", only: :dev} ]
  end
end
