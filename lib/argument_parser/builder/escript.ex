defmodule ArgumentParser.Builder.Escript do
  @moduledoc ~S"""
  `use` this module to have an ArgumentParser automatically parse your escript
  args. The macro will define a `main` function which parses script args and
  calls the `run` callback with the result`

  example:

      defmodule Foo.Escript do
        use ArgumentParser.Builder.Escript, add_help: :false
        @flag [:bar, alias: :b, action: :count]

        def run(%{bar: bar}) do
          IO.puts("#{bar} bars"
        end
      end


      $ mix escript.build
      $ ./foo -bbb
      3 bars
  """

  @doc """
  When `main` is called the arguments will be parsed and the result passed to
  `run`
  """
  @callback run(Map.t) :: any
  defmacro __using__(opts) do
    quote do
      unquote(ArgumentParser.Builder.setup(opts))
      @behaviour ArgumentParser.Builder.Escript
      
      def main(args) do
        {:ok, parsed} = parse(args)
        run(parsed)
      end
    end
  end
end
