defmodule ArgumentParser do
  alias ArgumentParser.Parser
  alias ArgumentParser.Help
  defstruct flags: [],
    positional: [],
    description: "",
    epilog: "",
    prefix_char: ?-,
    add_help: true,
    strict: true,
    exit: false

  @type t :: %__MODULE__{
    flags: [argument],
    positional: [argument],
    description: String.t,
    epilog: String.t,
    prefix_char: char,
    add_help: boolean,
    strict: boolean,
    exit: boolean}

  @type argument :: [argument_option]

  @type argument_option :: 
    atom |
    {:alias, atom} |
    {:action, action} |
    {:choices, term} |
    {:required, boolean} |
    {:default, term} |
    {:help, String.t} |
    {:metavar, atom}

  @type action :: 
    :store |
    {:store, nargs} |
    {:store, convert} |
    {:store, nargs, convert} |
    {:store_const, term} |
    :store_true |
    :store_false |
    :append |
    {:append, nargs} |
    {:append, convert} |
    {:append, nargs, convert} |
    {:append_const, term, atom} |
    :count |
    :help |
    {:version, String.t}

  @type nargs :: pos_integer | :'?' | :* | :+ | :remainder

  @type convert :: ((String.t) -> term)

  @doc """
  Create a new ArgumentParser

  example:

      iex> ArgumentParser.new(description: "Lorem Ipsum")
      %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                      prefix_char: ?-, epilog: "",
                      flags: [], positional: []}
  """
  @spec new(Dict.t) :: t
  def new(arguments \\ []) do
    struct(__MODULE__, arguments)
  end

  @doc """
  Append a flag arg to an ArgumentParser.

  example:

      iex> ArgumentParser.new(description: "Lorem Ipsum") |>
      ...>   ArgumentParser.add_flag(:foo, required: :false, action: :store_true)
      %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                      prefix_char: ?-, epilog: "",
                      flags: [[:foo, required: :false, action: :store_true]],
                      positional: []}
  """
  def add_flag(parser, flag) do
    flags = [flag | parser.flags]
    %{parser | flags: flags}
  end
  def add_flag(parser, name, opts) when is_atom(name) and is_list(opts) do
    add_flag(parser, [name | opts])
  end

  @doc """
  Append a positional arg to an ArgumentParser.

  example:

      iex> ArgumentParser.new(description: "Lorem Ipsum") |>
      ...>   ArgumentParser.add_arg(:foo, required: :false, action: :store_true)
      %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                      prefix_char: ?-, epilog: "",
                      flags: [],
                      positional: [[:foo, required: :false, action: :store_true]]}
  """
  def add_arg(parser, arg) do
    args = [arg | parser.positional]
    %{parser | positional: args}
  end
  def add_arg(parser, name, opts) when is_atom(name) and is_list(opts) do
    add_arg(parser, [name | opts])
  end

  @doc ~S"""
  Generate help string for a parser

  Will print the description,
  followed by a generated description of all arguments
  followed by an epilog.
  """
  @spec print_help(t) :: String.t
  def print_help(parser) do
    ArgumentParser.Help.describe(parser)
  end

  @doc ~S"""
  Parse arguments according to the passed ArgumentParser

  ## Arguments ##

  There are 2 types or arguments: positional and flag

  ### Flag Arguments ###

  Flag arguments are defined with a prefix char. The default is `-`.
  Flags can be either long form `--flag` or single character alias `-f`
  Alias flags can be grouped: `-flag` == `-f -l -a -g`
  Grouping only works if flags take no args.

  ### Positional arguments ###

  Positional arguments have as their first element an atom which is their name
  Positional arguments will be consumed in the order they are defined.
  For example:

      iex>ArgumentParser.parse(
      ...>  ArgumentParser.new(positional: [[:one], [:two]]),
      ...>  ["foo", "bar"])
      {:ok, %{one: "foo", two: "bar"}}

  ## Actions ##
  
  Valid actions are
  
      :store [default]           | collects one argument and sets as string
      {:store, nargs}            | collects [nargs] arguments and sets as string
      {:store, convert}          | collects one argument and applys [convert] to it
      {:store, nargs, convert}   | collects [nargs] arguments and applys [convert] to them
      {:store_const, term}       | sets value to [term] when flag is present
      :store_true                | sets value to true when flag is present
      :store_false               | sets value to false when flag is present
      :append                    | same as `:store`, but can use multiple times and stores as list
      {:append, nargs}           | ''
      {:append, convert}         | ''
      {:append, nargs, convert}  | ''
      {:append_const, term, atom}| ''
      :count                     | stores a count of # of times the flag is used
      :help                      | print help and exit
      {:version, version_sting}  | print version_sting and exit      

  examples:

      iex> ArgumentParser.new(flags: [[:tru, action: :store_true],
      ...>                            [:fls, action: :store_false],
      ...>                            [:cst, action: {:store_const, Foo}]]) |>
      ...>  ArgumentParser.parse(~w[--tru --fls --cst])
      {:ok, %{tru: true, fls: false, cst: Foo}}

      iex> ArgumentParser.new() |>
      ...>   ArgumentParser.add_flag(:apnd, action: :append) |>
      ...>   ArgumentParser.add_arg(:star, action: {:store, :*}) |>
      ...>   ArgumentParser.parse(~w[--apnd foo one two --apnd bar])
      {:ok, %{apnd: ["bar", "foo"], star: ["one", "two"]}}

  ### nargs ###

  nargs can be:

      postitive integer N | collect the next [N] arguments
      :*                  | collect remaining arguments until a flag argument in encountered
      :+                  | same as :* but thows an error if no arguments are collected
      :'?'                | collect one argument if there is any left
      :remainder          | collect all remaining args regardless of type
  
  actions `:store` and `:append` are the same as `{:store, 1}` and `{:append, 1}`

      iex> ArgumentParser.new() |> 
      ...>   ArgumentParser.add_flag(:apnd, action: :append) |>
      ...>   ArgumentParser.add_arg(:rmdr, action: {:store, :remainder}) |>
      ...>   ArgumentParser.parse(~w[--apnd foo one two --apnd bar])
      {:ok, %{apnd: ["foo"], rmdr: ["one", "two", "--apnd", "bar"]}}

  ### convert ###

  Convert can be any function with an arity of 1.
  If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

      iex> ArgumentParser.new(positional: [
      ...>     [:hex, action: {:store, &String.to_integer(&1, 16)}]]) |>
      ...>   ArgumentParser.parse(["BADA55"])
      {:ok, %{hex: 12245589}}

  ## Choices ##

  A list of terms. If an argument is passed that does not match the coices an
  error will be returned.

      iex> ArgumentParser.new() |>
      iex>   ArgumentParser.add_arg([:foo, choices: ["a", "b", "c"]]) |>
      iex>   ArgumentParser.parse(["foo", "x"], :false)
      {:error, "value for foo should be one of [\"a\", \"b\", \"c\"], got foo"}

  ## Required ##

  If true an error will be thown if a value is not set. Defaults to false.

  ## Default ##

  Default value.

      iex> ArgumentParser.new(positional: [[:dft, default: :foo]]) |>
      ...>   ArgumentParser.parse([])
      {:ok, %{dft: :foo}}

  ## Help ##
   
  String to print for this flag's entry in the generated help output

  """
  @spec parse(t, [String.t], boolean) :: Parser.result
  def parse(parser, args, print_and_exit \\ :true) do
    Parser.parse(args, parser) |>
        handle(print_and_exit, parser)
  end

  defp handle({:ok, result}, _, _) do
    {:ok, result}
  end
  defp handle({:message, msg}, :true, _) do
    IO.puts(msg)
    exit(:normal)
  end
  defp handle({:error, reason}, :true, parser) do
    IO.puts("error: #{inspect(reason)}")
    IO.puts(print_help(parser))
  end
  defp handle(result, :false, _) do
    result
  end
end
