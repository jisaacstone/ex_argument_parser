defmodule ArgumentParser.Builder do
  @moduledoc ~S"""
  Utility for easily creating modules that parse args using ArgumentParser.

  `@arg` and `@flag` attributes can be used to define arguments similar to
  the `add_flag/2` and `add_arg/2` functions.

  Will create a private `parse` function.

  The first argument to the parser function should be a list of binarys.
  the second option is the `print_and_exit` flag, which defaults to `:true`.

      parse([binary], :true) :: {:ok, Map.t}
      parse([binary], :false) :: {:ok, Map.t} | {:error, term} | {:message,
        iodata}

  When the `print_and_exit` flag is `:true` messages and errors will be printed
  to stdout and the process will exit.
  
  ArgumentParser options can be passed in the `use` options.

     use ArgumentParser.Builder, add_help: :false, strict: :true

  If `:description` is not passed the `@shortdoc` or `@moduledoc` will be used
  if present.

  Example:

      defmodule Script.Example do
        use ArgumentParser.Builder
        @arg [:name]
        @flag [:bar, alias: :b, help: "get some beer at the bar"]

        def run(args) do
          {:ok, parsed} = parse(args)
          main(parsed)
        end

        def main(%{name: "Homer"}) do
          IO.puts("No Homers!")
        end
        def main(%{name: name, bar: bar}) do
          IO.puts("Hey #{name} let's go to #{bar}!")
        end
      end
  """

  @doc :false
  defmacro __using__(opts) do
    setup(opts)
  end

  @doc :false
  def setup(opts) do
    quote do
      Enum.each(
        [:shortdoc, :recursive],
        &Module.register_attribute(__MODULE__, &1, persist: true))
      Enum.each(
        [:arg, :flag],
        &Module.register_attribute(__MODULE__, &1, accumulate: true))
      @argparse_opts unquote(opts)
      @before_compile ArgumentParser.Builder
    end
  end

  @doc :false
  defmacro __before_compile__(env) do
    attr = &Module.get_attribute(env.module, &1)
    args = attr.(:arg)
    flags = attr.(:flag)
    opts = attr.(:argparse_opts)
    desc = cond do
      Dict.has_key?(opts, :description) -> opts[:description]
      String.valid?(sd = attr.(:shortdoc)) -> sd
      String.valid?(md = attr.(:moduledoc)) -> md
      true -> ""
    end

    parser = opts |>
      Dict.merge(flags: flags, positional: args, description: desc) |>
      ArgumentParser.new() |>
      Macro.escape()

    quote do
      defp parse(arguments, exit \\ :true) do
        ArgumentParser.parse(unquote(parser), arguments, exit)
      end
    end
  end
end
