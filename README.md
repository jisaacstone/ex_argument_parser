# ArgumentParser

## Arguments ##

There are 2 types or arguments: positional and flag

### Flag Arguments ###
Flag arguments are defined with a prefix char. The default is `-`.
Flag arguments have as their first element a list of flags e.g. `[--foo, -f]`
The name of a flag arg will be an atom derived from the longest flag name.
For example the above list would generate a name of `:foo`
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
    :append                    | same as `:store`, but can use multiple times and storse as list
    {:append, nargs}           | ''
    {:append, convert}         | ''
    {:append, nargs, convert}  | ''
    {:append_const, term, atom}| ''
    :count                     | stores a count of # of times the flag is used
    :help                      | print help and exit
    {:version, version_sting}  | print version_sting and exit      

### nargs ###

nargs can be:

    postitive integer N | collect the next [N] arguments
    :*                  | collect remaining arguments until a flag argument in encountered
    :+                  | same as :* but thows an error if no arguments are collected
    :'?'                | collect one argument if there is any left
    :remainder          | collect all remaining args regardless of type

The default is 1

### convert ###

Convert can be any function with an arity of 1.
If nargs is 1 or :'?' a String will be passed, otherwise a list of String will be

## Choices ##

A list of terms. If an argument is passed that does not match the coices an error will be thrown

## Required ##

If true an error will be thown if a value is not set. Defaults to false.

## Default ##

Default value.

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
