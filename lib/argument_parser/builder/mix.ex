defmodule ArgumentParser.Builder.Mix do
  @moduledoc ~S"""
  Similar to `ArgumentParser.Builder`, but will automatically create a `run`
  function that parsed the args and calls the `main` function with the result.

      defmodule Mix.Task.Drinks do
        use ArgumentParser.Builder.Mix
        @flag [:coffee, default: "black"]
        @flag [:tea, default: "green"]

        def main(%{coffee: coffee, tea: tea}) do
          IO.puts("Today we have %{coffee} coffee and #{tea} tea")
        end
      end


      $ mix drinks --tea puer
      Today we have black coffee and puer tea

  """

  @doc """
  When `run` is called the arguments will be parsed and the result passed to
  `main`
  """
  @callback main(Map.t) :: any
  defmacro __using__(opts) do
    quote do
      unquote(ArgumentParser.Builder.setup(opts))
      @behaviour ArgumentParser.Builder.Mix
      
      @doc :false
      def run(args) do
        {:ok, parsed} = parse(args)
        main(parsed)
      end
    end
  end
end
