# ArgumentParser

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
    :prefix_char | Char preceding flag arguments. Default `-`
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

## Actions <a name="action"></a>

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

### nargs <a name="nargs"></a>

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

### convert  <a name="convert"></a>

Convert can be any function with an arity of 1.
If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

    iex> ArgumentParser.new(positional: [
    ...>     [:hex, action: {:store, &String.to_integer(&1, 16)}]]) |>
    ...>   ArgumentParser.parse(["BADA55"])
    {:ok, %{hex: 12245589}}

## Choices <a name="choices"></a>

A list of terms. If an argument is passed that does not match the coices an
error will be returned.

    iex> ArgumentParser.new() |>
    iex>   ArgumentParser.add_arg([:foo, choices: ["a", "b", "c"]]) |>
    iex>   ArgumentParser.parse(["foo", "x"], :false)
    {:error, "value for foo should be one of ["a", "b", "c"], got foo"}

## Required <a name="required"></a>

If true an error will be thown if a value is not set. Defaults to false.

__flags only__

## Default <a name="default"></a>

Default value. 

    iex> ArgumentParser.new(positional: [[:dft, default: :foo]]) |>
    ...>   ArgumentParser.parse([])
    {:ok, %{dft: :foo}}

## Help <a name="help">
 
String to print for this flag's entry in the generated help output


## Types <a name="types"></a>

### <a href="#t:action/0">action</a> ::
  :store |
  {:store, <a href="#t:nargs/0">nargs</a>} |
  {:store, <a href="#t:convert/0">convert</a>} |
  {:store, <a href="#t:nargs/0">nargs</a>, <a href="#t:convert/0">convert</a>} |
  {:store_const, term} |
  :store_true |
  :store_false |
  :append |
  {:append, <a href="#t:nargs/0">nargs</a>} |
  {:append, <a href="#t:convert/0">convert</a>} |
  {:append, <a href="#t:nargs/0">nargs</a>, <a href="#t:convert/0">convert</a>} |
  {:append_const, term, atom} |
  :count |
  :help |
  {:version, <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>}

### <a href="#t:argument/0">argument</a> :: [atom | <a href="#t:argument_option/0">argument_option</a>]

### <a href="#t:argument_option/0">argument_option</a> ::
  {:alias, atom} |
  {:action, <a href="#t:action/0">action</a>} |
  {:choices, term} |
  {:required, boolean} |
  {:default, term} |
  {:help, <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>} |
  {:metavar, atom}

### <a href="#t:convert/0">convert</a> :: (<a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a> -> term)

### <a href="#t:nargs/0">nargs</a> :: pos_integer | :"?" | :* | :+ | :remainder

### <a href="#t:t/0">t</a> :: %ArgumentParser{add_help: boolean, description: <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>, epilog: <a href="http://elixir-lang.org/docs/stable/elixir/String.html#t:t/0">String.t</a>, flags: [<a href="#t:argument/0">argument</a>], positional: [<a href="#t:argument/0">argument</a>], prefix_char: char, strict: boolean}

## Functions <a name="functions"></a>

### print_help(parser) <a name="f:print_help/1"></a>

Generate help string for a parser

Will print the description,
followed by a generated description of all arguments
followed by an epilog.


### parse(parser, args, print_and_exit \\ true) <a name="f:parse/3"></a>

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


### new(arguments \\ []) <a name="f:new/1"></a>

Create a new ArgumentParser

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum")
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                    prefix_char: ?-, epilog: "",
                    flags: [], positional: []}


### add_flag(parser, name, opts) <a name="f:add_flag/3"></a>

### add_flag(parser, flag) <a name="f:add_flag/2"></a>

Append a flag arg to an ArgumentParser.

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum") |>
    ...>   ArgumentParser.add_flag(:foo, required: :false, action: :store_true)
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                    prefix_char: ?-, epilog: "",
                    flags: [[:foo, required: :false, action: :store_true]],
                    positional: []}


### add_arg(parser, name, opts) <a name="f:add_arg/3"></a>

### add_arg(parser, arg) <a name="f:add_arg/2"></a>

Append a positional arg to an ArgumentParser.

example:

    iex> ArgumentParser.new(description: "Lorem Ipsum") |>
    ...>   ArgumentParser.add_arg(:foo, required: :false, action: :store_true)
    %ArgumentParser{description: "Lorem Ipsum", add_help: :true,
                    prefix_char: ?-, epilog: "",
                    flags: [],
                    positional: [[:foo, required: :false, action: :store_true]]}


