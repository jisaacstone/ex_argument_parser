# ArgumentParser

Tool for accepting command-line arguments, intended to be functionally similar to python's argparse

Main functions:

    print_help(%ArgumentParser{}, opts \\ [])

Will print a helpful message on how to use the tool. Most of it is generated based on the `:flags`
and `:positional` arguments of the `ArgumentParser` struct. Will exit after printing if `exit: true` is passed.

    parse([argument list], %ArgumentParser{})

Will attempt to parse the aruments. If sucessful it will return a dict with the parsed args. If unsuccessful it
will return an {:error, message} tuple.

    parse!([argument list], %ArgumentParser{})

Same as above except if unsuccessful it will print the error message and help message, then exit.

## Parser ##

`ArgumentParser` is a struct with the following attributes:

    :flags       | A list of Flag Arguments
    :positional  | A list of Positional Arguments
    :description | A string to print before generated help
    :epilog      | A string to print after generated help
    :prefix_char | Char preceding flag arguments. Default -
    :add_help    | Print help when -h or --help is passed. Default true
    :strict      | Throw an error when an unexpected argument is found Default false
    :exit        | boolean, should we exit if encountering an error or help flag?

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

```elixir
    iex>ArgumentParser.parse(["foo", "bar"], %ArgumentParser{positional: [[:one], [:two]]})
    %{one: "foo", two: "bar"}
```

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

```elixir
    iex>ArgumentParser.parse(~w[--tru --fls --cst],
    ...> %ArgumentParser{flags: [[:tru, action: :store_true],
    ...>                         [:fls, action: :store_false],
    ...>                         [:cst, action: {:store_const, Foo}]])
    %{tru: true, fls: false, cst: Foo}

    iex>ArgumentParser.parse(~w[--apnd foo one two --apnd bar],
    ...> %ArgumentParser{flags: [[:apnd, action: :append]],
    ...>                 positional: [[:star, action: {:store, :*}]]})
    %{apnd: ["foo", "bar"], star: ["one, "two"]}
```

### nargs ###

nargs can be:

    postitive integer N | collect the next [N] arguments
    :*                  | collect remaining arguments until a flag argument in encountered
    :+                  | same as :* but thows an error if no arguments are collected
    :'?'                | collect one argument if there is any left
    :remainder          | collect all remaining args regardless of type

actions `:store` and `:append` are the same as `{:store, 1}` and `{:append, 1}`

```elixir
    iex>ArgumentParser.parse(~w[--apnd foo one two --apnd bar],
    ...> %ArgumentParser{flags: [[:apnd, action: :append]],
    ...>                 positional: [[:rmdr, action: {:store, :remainder}]]})
    %{apnd: ["foo"], rmdr: ["one, "two", "--apnd", "bar"]}
```

### convert ###

Convert can be any function with an arity of 1.
If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

```elixir
    iex>ArgumentParser.parse(["BADA55"],
    ...> %ArgumentParser{positional: [[:hex, action: {:store, &String.to_integer(&1, 16)}]]})
    %{hex: 12245589}
```

## Choices ##

A list of terms. If an argument is passed that does not match the coices an error will be thrown

## Required ##

If true an error will be thown if a value is not set. Defaults to false.

## Default ##

Default value.

```elixir
    iex>ArgumentParser.parse([],
    ...> %ArgumentParser{positional: [[:dft, default: :foo]]})
    %{dft: :foo}
```

## Help ##

String to print for this flag's entry in the generated help output

## Installation ##

Add argument_parser to your list of dependencies in mix.exs:

```elixir
  def deps do
    [{:argument_parser, git: "git@github.com:jisaacstone/ex_argument_parser.git"}]
  end
```

