[`Elixir.ArgumentParser`](#Elixir.ArgumentParser)

[`Elixir.ArgumentParser.Builder`](#Elixir.ArgumentParser.Builder)

[`Elixir.ArgumentParser.Builder.Mix`](#Elixir.ArgumentParser.Builder.Mix)

[`Elixir.ArgumentParser.Builder.Escript`](#Elixir.ArgumentParser.Builder.Escript)

# ArgumentParser

<a name="ArgumentParser"></a>

* [Description](#description)
* [Types](#types)
* [Functions](#functions)

## Description <a name="description"></a>

Tool for accepting command-line arguments, intended to be functionally similar to python's argparse

## Parser ##

[`ArgumentParser`](ArgumentParser.html#content) is a struct with the following attributes:

    :flags       | A list of Flag Arguments
    :positional  | A list of Positional Arguments
    :description | A string to print before generated help
    :epilog      | A string to print after generated help
    :add_help    | Print help when -h or --help is passed. Default true
    :strict      | Throw an error when an unexpected argument is found. Default false

An ArgumentParser can be created with `new`. Positional args can be added
with `add_arg`, flags with `add_flag`. When the parser is setup use
`parse` to parse.

## Arguments ##

There are 2 types or arguments: positional and flag

Arguments are option lists where the first element is the name of the argument
as an atom. This name will be the key of the map returned by `parse`.

Arguments take the following options:
* [`alias`](#alias)
* [`action`](#action)
* [`choices`](#choices)
* [`required`](#required)
* [`default`](#default)
* [`help`](#help)
* [`metavar`](#metavar)

### Flag Arguments ###

Flags can be either long form `--flag` or single character alias `-f`
Alias flags can be grouped: `-flag` == `-f -l -a -g`
Grouping only works if flags take no args.

### Positional Arguments ###

Positional arguments have as their first element an atom which is their name
Positional arguments will be consumed in the order they are defined.
For example:

    iex>ArgumentParser.parse(
    ...>  ArgumentParser.new(positional: [[:one], [:two]]),
    ...>  ["foo", "bar"])
    {:ok, %{one: "foo", two: "bar"}}

## Actions <a name="action"></a>

Valid actions are

    {:store, nargs}            | collects [nargs] arguments and sets as string
    {:store, convert}          | collects one argument and applys [convert] to it
    {:store, nargs, convert}   | collects [nargs] arguments and applys [convert] to them
    {:store_const, term}       | sets value to [term] when flag is present
    :store_true                | sets value to true when flag is present
    :store_false               | sets value to false when flag is present
    :count                     | stores a count of # of times the flag is used
    :help                      | print help and exit
    {:version, version_sting}  | print version_sting and exit      

The default action is `{:store, 1}`.

Examples:

    iex> ArgumentParser.new(flags: [[:tru, action: :store_true],
    ...>                            [:fls, action: :store_false],
    ...>                            [:cst, action: {:store_const, Foo}]]) |>
    ...>  ArgumentParser.parse(~w[--tru --fls --cst])
    {:ok, %{tru: true, fls: false, cst: Foo}}

    iex> ArgumentParser.new() |>
    ...>   ArgumentParser.add_flag(:cnt, action: :count) |>
    ...>   ArgumentParser.add_arg(:star, action: {:store, :*}) |>
    ...>   ArgumentParser.parse(~w[--cnt one two --cnt])
    {:ok, %{cnt: 2, star: ["one", "two"]}}

### nargs <a name="nargs"></a>

nargs can be:

    postitive integer N | collect the next [N] arguments
    :*                  | collect remaining arguments until a flag argument in encountered
    :+                  | same as :* but thows an error if no arguments are collected
    :'?'                | collect one argument if there is any left
    :remainder          | collect all remaining args regardless of type

`:store` is the same as `{:store, 1}`

    iex> ArgumentParser.new() |> 
    ...>   ArgumentParser.add_flag(:star, action: {:store, :*}) |>
    ...>   ArgumentParser.add_arg(:rmdr, action: {:store, :remainder}) |>
    ...>   ArgumentParser.parse(~w[one two --apnd bar])
    {:ok, %{star: [], rmdr: ["one", "two", "--apnd", "bar"]}}

### convert  <a name="convert"></a>

Convert can be any function with an arity of 1.
If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

    iex> ArgumentParser.new(positional: [
    ...>     [:hex, action: {:store, &String.to_integer(&1, 16)}]]) |>
    ...>   ArgumentParser.parse(["BADA55"])
    {:ok, %{hex: 12245589}}

### choices <a name="choices"></a>

A list of terms. If an argument is passed that does not match the coices an
error will be returned.

    iex> ArgumentParser.new() |>
    ...>   ArgumentParser.add_arg([:foo, choices: ["a", "b", "c"]]) |>
    ...>   ArgumentParser.parse(["foo", "x"], :false)
    {:error, "value for foo should be one of [\"a\", \"b\", \"c\"], got foo"}

### required <a name="required"></a>

If true an error will be thown if a value is not set. Defaults to false.

__flags only__

### default <a name="default"></a>

Default value. 

    iex> ArgumentParser.new(positional: [[:dft, default: :foo]]) |>
    ...>   ArgumentParser.parse([])
    {:ok, %{dft: :foo}}

### help <a name="help">
 
String to print for this flag's entry in the generated help output


## Types <a name="types"></a>

<pre><a href="#t:action/0">action</a> ::
  :store |
  {:store, <a href="#t:nargs/0">nargs</a>} |
  {:store, <a href="#t:convert/0">convert</a>} |
  {:store, <a href="#t:nargs/0">nargs</a>, <a href="#t:convert/0">convert</a>} |
  {:store_const, term} |
  :store_true |
  :store_false |
  :count |
  :help |
  {:version, <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>}

<a href="#t:argument/0">argument</a> :: [atom | <a href="#t:argument_option/0">argument_option</a>]

<a href="#t:argument_option/0">argument_option</a> ::
  {:alias, atom} |
  {:action, <a href="#t:action/0">action</a>} |
  {:choices, term} |
  {:required, boolean} |
  {:default, term} |
  {:help, <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>} |
  {:metavar, atom}

<a href="#t:convert/0">convert</a> :: (<a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a> -> term)

<a href="#t:nargs/0">nargs</a> :: pos_integer | :"?" | :* | :+ | :remainder

<a href="#t:t/0">t</a> :: %ArgumentParser{add_help: boolean, description: <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>, epilog: <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>, flags: [<a href="#t:argument/0">argument</a>], positional: [<a href="#t:argument/0">argument</a>], strict: boolean}

</pre>## Functions <a name="functions"></a>

### print_help(parser) <a name="print_help/1"></a>

Generate help string for a parser

Will print the description,
followed by a generated description of all arguments
followed by an epilog.


### parse(parser, args, print_and_exit \\ true) <a name="parse/3"></a>

Parse arguments according to the passed ArgumentParser.

Usually returns an `{:ok, result}` tuple. Exceptions are:

### if error was encountered during parsing

If `print_and_exit` is `:true` a helpful error message is sent to stdout and
the process exits.
If `print_and_exit` is `:false` an `{:error, reason}` tuple is returned.

### if help or version message should be printed

If `print_and_exit` is `:true` the message is sent to stdout and
the process exits.
If `print_and_exit` is `:false` a `{:message, string}` tuple is returned.


### new(arguments \\ []) <a name="new/1"></a>

Create a new ArgumentParser

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum")
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                    epilog: "", flags: [], positional: []}


### add_flag(parser, name, opts) <a name="add_flag/3"></a>

### add_flag(parser, flag) <a name="add_flag/2"></a>

Append a flag arg to an ArgumentParser.

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum") |>
    ...>   ArgumentParser.add_flag(:foo, required: :false, action: :store_true)
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true, epilog: "",
                    flags: [[:foo, required: :false, action: :store_true]],
                    positional: []}


### add_arg(parser, name, opts) <a name="add_arg/3"></a>

### add_arg(parser, arg) <a name="add_arg/2"></a>

Append a positional arg to an ArgumentParser.

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum") |>
    ...>   ArgumentParser.add_arg(:foo, required: :false, action: :store_true)
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                    epilog: "", flags: [],
                    positional: [[:foo, required: :false, action: :store_true]]}


# ArgumentParser.Builder

<a name="ArgumentParser.Builder"></a>

* [Description](#description)

## Description <a name="description"></a>

Utility for easily creating modules that parse args using ArgumentParser.

`@arg` and `@flag` attributes can be used to define arguments similar to
the `add_flag/2` and `add_arg/2` functions.

Will create a private `parse` function.

The first argument to the parser function should be a list of binarys.
the second option is the `print_and_exit` flag, which defaults to `:true`.

    parse([binary], :true) :: {:ok, map()}
    parse([binary], :false) :: {:ok, map()} | {:error, term} | {:message,
      iodata}

When the `print_and_exit` flag is `:true` messages and errors will be printed
to stdout and the process will exit.

ArgumentParser options can be passed in the `use` options.

   use ArgumentParser.Builder, add_help: :false, strict: :true

If `:description` is not passed the `@shortdoc` or `@moduledoc` will be used
if present.

If no `@moduledoc` is defined for the module then the help message for the
argument parser will be set as the `@moduledoc`. To disable this behaviour
explicitly use `@moduledoc :false`.

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

# ArgumentParser.Builder.Mix

<a name="ArgumentParser.Builder.Mix"></a>

* [Description](#description)
* [Callbacks](#callbacks)

## Description <a name="description"></a>

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


## Callbacks <a name="callbacks"></a>

### main(arg0) <a name="main/1"></a>

When `run` is called the arguments will be parsed and the result passed to
`main`


# ArgumentParser.Builder.Escript

<a name="ArgumentParser.Builder.Escript"></a>

* [Description](#description)
* [Callbacks](#callbacks)

## Description <a name="description"></a>

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

## Callbacks <a name="callbacks"></a>

### run(arg0) <a name="run/1"></a>

When `main` is called the arguments will be parsed and the result passed to
`run`
