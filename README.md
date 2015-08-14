# ArgumentParser

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

    iex>ArgumentParser.parse(["foo", "bar"], %ArgumentParser{positional: [[:one], [:two]]})
    %{one: "foo", two: "bar"}

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

    iex>ArgumentParser.parse(~w[--tru --fls --cst],
    ...> %ArgumentParser{flags: [[:tru, action: :store_true],
    ...>                         [:fls, action: :store_false],
    ...>                         [:cst, action: {:store_const, Foo}]])
    %{tru: true, fls: false, cst: Foo}

    iex>ArgumentParser.parse(~w[--apnd foo one two --apnd bar],
    ...> %ArgumentParser{flags: [[:apnd, action: :append]],
    ...>                 positional: [[:star, action: {:store, :*}]]})
    %{apnd: ["foo", "bar"], star: ["one, "two"]}

### nargs ###

nargs can be:

    postitive integer N | collect the next [N] arguments
    :*                  | collect remaining arguments until a flag argument in encountered
    :+                  | same as :* but thows an error if no arguments are collected
    :'?'                | collect one argument if there is any left
    :remainder          | collect all remaining args regardless of type

actions `:store` and `:append` are the same as `{:store, 1}` and `{:append, 1}`

    iex>ArgumentParser.parse(~w[--apnd foo one two --apnd bar],
    ...> %ArgumentParser{flags: [[:apnd, action: :append]],
    ...>                 positional: [[:rmdr, action: {:store, :remainder}]]})
    %{apnd: ["foo"], rmdr: ["one, "two", "--apnd", "bar"]}

### convert ###

Convert can be any function with an arity of 1.
If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

    iex>ArgumentParser.parse(["BADA55"],
    ...> %ArgumentParser{positional: [[:hex, action: {:store, &String.to_integer(&1, 16)}]]})
    %{hex: 12245589}

## Choices ##

A list of terms. If an argument is passed that does not match the coices an error will be thrown

## Required ##

If true an error will be thown if a value is not set. Defaults to false.

## Default ##

Default value.

    iex>ArgumentParser.parse([],
    ...> %ArgumentParser{positional: [[:dft, default: :foo]]})
    %{dft: :foo}

## Help ##

String to print for this flag's entry in the generated help output

## Installation

  1. Add argument_parser to your list of dependencies in mix.exs:

        def deps do
          [{:argument_parser, "~> 0.0.1"}]
        end

  2. Ensure argument_parser is started before your application:

        def application do
          [applications: [:argument_parser]]
        end
