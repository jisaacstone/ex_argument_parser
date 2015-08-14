defmodule ArgumentParser do
  defstruct flags: [],
    positional: [],
    description: "",
    epilog: "",
    prefix_char: ?-,
    add_help: true,
    strict: false

  @type t :: %ArgumentParser{}

  @type argument :: [
    alias: atom,
    action: action,
    choices: term,
    required: boolean,
    default: term,
    help: String.t,
    metavar: atom]

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

  @narg_atoms [:'?', :*, :+, :remainder]

  @doc ~S"""
  Print help for a parser
  Will print the description,
  followed by a generated description of all arguments
  followed by an epilog.
  """
  def print_help(parser) do
    (desc = Keyword.get(parser, :description)) && IO.puts(desc)
    IO.inspect parser.flags
    IO.inspect parser.positional
    (epilog = Keyword.get(parser, :epilog)) && IO.puts(epilog)
    exit(:normal)
  end

  @doc ~S"""
  Parse arguments according to the passed ArgumentParser
 
  ## Arguments ##

  There are 2 types or arguments: positional and flag

  ###Flag Arguments###
  Flag arguments are defined with a prefix char. The default is `-`.
  Flag arguments have as their first element a list of flags e.g. `[--foo, -f]`
  The name of a flag arg will be an atom derived from the longest flag name.
  For example the above list would generate a name of `:foo`
  Flags can be either long form `--flag` or single character alias `-f`
  Alias flags can be grouped: `-flag` == `-f -l -a -g`
  Grouping only works if flags take no args.

  ###Positional arguments###
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

  """

  @spec parse([String.t], t) :: %{}
  def parse(args, parser) do
    parse(args, parser, %{}) |>
      check_arguments(parser)
  end
  defp parse([], _parser, parsed) do
    parsed
  end
  # -h
  defp parse([<<pc, ?h>> | _],
             %{add_help: true, prefix_char: pc} = parser, _) do
    print_help(parser)
  end
  # --help
  defp parse([<<pc, pc, ?h, ?e, ?l, ?p>> | _],
             %{add_help: true, prefix_char: pc} = parser, _) do
    print_help(parser)
  end
  # --[flag]
  defp parse([<<pc, pc, arg :: binary>> | rest],
             %{prefix_char: pc} = parser,
             parsed) do
    argument = get_flag_by_name(
      String.to_atom(arg), parser.flags, parser.strict)
    {rest, parsed} = apply_argument(argument, rest, parsed, parser)
    parse(rest, parser, parsed)
  end
  # -[alias]+ (e.g. -aux -> -a -u -x)
  defp parse([<<pc, aliased :: binary>> | rest],
             %{prefix_char: pc} = parser,
             parsed) do
    {rest, parsed} = unalias_and_apply(aliased, rest, parsed, parser)
    parse(rest, parser, parsed)
  end
  # positional args
  defp parse(args,
             %{positional: [head | tail]} = parser,
             parsed) do
    {rest, parsed} = apply_argument(head, args, parsed, parser)
    parse(rest, %{parser | positional: tail}, parsed)
  end
  # unexpected positional arg
  defp parse([head | tail], parser, parsed) do
    if parser.strict do
      exit_bad_args("Unexpected argument #{head}")
    else
      parse(tail, parser, Dict.put(parsed, String.to_atom(head), true))
    end
  end

  # Check for required args and set defaults
  defp check_arguments(parsed, parser) do
    Stream.concat(parser.positional, parser.flags) |>
    Stream.map(fn(a) -> {a, key_for(a)} end) |>
    Stream.reject(&Dict.has_key?(parsed, elem(&1, 1))) |>
    Enum.reduce(parsed, &check_argument/2)
  end

  defp check_argument({argument, key}, parsed) do
    case Keyword.fetch(argument, :default) do
      {:ok, value} -> Dict.put_new(parsed, key, value)
      :error ->
        action = Keyword.get(argument, :action)
        cond do
          action == :count ->
            Dict.put_new(parsed, key, 0)
          action == :store_true ->
            Dict.put_new(parsed, key, false)
          action == :store_false ->
            Dict.put_new(parsed, key, true)
          Keyword.get(argument, :required) ->
            exit_bad_args("missing required arg #{key}")
          true ->
            parsed
        end
    end
  end

  defp get_flag_by_name(name, arguments, strict) do
    get_flag(name, arguments, strict, &hd/1)
  end
  defp get_flag_by_alias(name, arguments, strict) do
    get_flag(name, arguments, strict, &Keyword.get(&1, :alias))
  end
  defp get_flag(ident, [], true, _) do
    exit_bad_args("invalid flag: #{ident}")
  end
  defp get_flag(ident, [], false, _) do
    [ident]
  end
  defp get_flag(ident, [head | tail], strict, getter) do
    if getter.(head) == ident do
      head
    else
      get_flag(ident, tail, strict, getter)
    end
  end

  defp unalias_and_apply(<<alias>>, args, parsed, parser) do
    # single alias is simple case
    argument = get_flag_by_alias(
      List.to_atom([alias]), parser.flags, parser.strict)
    apply_argument(argument, args, parsed, parser)
  end
  defp unalias_and_apply(<<alias, rest :: binary>>, args, parsed, parser) do
    argument = get_flag_by_alias(
      List.to_atom([alias]), parser.flags, parser.strict)
    case apply_argument(argument, [rest | args], parsed, parser) do
      {[rest | args], parsed} ->
        # sometimes alias flags are grouped together: -frt == -f -r -t
        unalias_and_apply(rest, args, parsed, parser)
      result ->
        # sometimes it is a single alias with a value: -frf == --foo rt
        result
    end
  end

  defp exit_bad_args(message) do
    IO.puts(message)
    exit(:normal)
  end

  defp key_for([name | _]) when is_atom(name) do
    name
  end
  defp key_for([flags | _]) when is_list(flags) do
    case Enum.max_by(flags, &String.length/1) do
      <<pc, pc, arg :: binary>> ->
        String.to_atom(arg)
      <<_pc, arg :: binary>> ->
        String.to_atom(arg)
    end
  end

  defp apply_argument(argument, args, parsed, parser) do
    key = key_for(argument)
    {args, parsed} = apply_action(
      Keyword.get(argument, :action, :store),
      args,
      key,
      parsed,
      parser)
    if choices = Keyword.get(argument, :choices) do
      if not (actual = Dict.get(parsed, key)) in choices do
        exit_bad_args("value for #{key} should be in #{inspect(choices)}, got #{actual}")
      end
    end
    {args, parsed}
  end

  defp apply_action(action, _, key, %{key: _}, _)
  when (is_atom(action) and action != :append)
  or (is_tuple(action) and not elem(action, 0) in [:append, :append_const]) do
    exit_bad_args("duplicate key #{key}")
  end
  defp apply_action(:store, [head | args], key, parsed, _parser) do
    {args, Dict.put(parsed, key, head)}
  end
  defp apply_action({:store, f}, [head | args], key, parsed, _parser)
  when is_function(f) do
    {args, Dict.put(parsed, key, f.(head))}
  end
  defp apply_action({:store, n}, args, key, parsed, parser)
  when is_number(n) or n in @narg_atoms do
    {value, rest} = fetch_nargs(args, n, parser)
    {rest, Dict.put_new(parsed, key, value)}
  end
  defp apply_action({:store, n, f}, args, key, parsed, parser)
  when is_function(f) and (is_number(n) or n in @narg_atoms) do
    {value, rest} = fetch_nargs(args, n, parser)
    newvalue = if is_list(value) do
      Enum.map(value, f)
    else
      f.(value)
    end
    {rest, Dict.put_new(parsed, key, newvalue)}
  end
  defp apply_action(:store_true, args, key, parsed, _parser) do
    {args, Dict.put_new(parsed, key, true)}
  end
  defp apply_action(:store_false, args, key, parsed, _parser) do
    {args, Dict.put_new(parsed, key, false)}
  end
  defp apply_action({:store_const, const}, args, key, parsed, _parser) do
    {args, Dict.put_new(parsed, key, const)}
  end
  defp apply_action(:append, [head | args], key, parsed, _parser) do
    {args, Dict.update(parsed, key, [head], &([head | &1]))}
  end
  defp apply_action({:append, f}, [head | args], key, parsed, _parser)
  when is_function(f) do
    value = f.(head)
    {args, Dict.update(parsed, key, [value], &([value | &1]))}
  end
  defp apply_action({:append, n}, args, key, parsed, parser)
  when is_number(n) or n in @narg_atoms do
    {value, rest} = fetch_nargs(args, n, parser)
    {rest, Dict.update(parsed, key, [value], &([value | &1]))}
  end
  defp apply_action({:append, n, f}, args, key, parsed, parser)
  when is_function(f) and (is_number(n) or n in @narg_atoms) do
    {value, rest} = fetch_nargs(args, n, parser)
    value = f.(value)
    {rest, Dict.update(parsed, key, [value], &([value | &1]))}
  end
  defp apply_action({:append_const, const, key}, args, _key, parsed, _parser) do
    {args, Dict.update(parsed, key, [const], &([const | &1]))}
  end
  defp apply_action(:count, args, key, parsed, _parser) do
    {args, Dict.update(parsed, key, 1, &(&1 + 1))}
  end
  defp apply_action(:help, _, _, _, parser) do
    print_help(parser)
  end
  defp apply_action({:version, version}, _, _, _, _) do
    IO.puts(version)
    exit(:normal)
  end

  defp fetch_nargs(args, n, _parser) when is_number(n) do
    Enum.split(args, n)
  end
  defp fetch_nargs(args, :remainder, _parser) do
    {args, []}
  end
  defp fetch_nargs(args, :*, parser) do
    Enum.split_while(args, &(not is_flag(&1, parser.prefix_char)))
  end
  defp fetch_nargs(args, :+, parser) do
    case Enum.split_while(args, &(not is_flag(&1, parser.prefix_char))) do
      {[], _} -> exit_bad_args("Missing value")
      result  -> result
    end
  end
  defp fetch_nargs([head | tail] = args, :'?', parser) do
    if is_flag(head, parser.prefix_char) do
      {[], args}
    else
      {head, tail}
    end
  end
  defp fetch_nargs([], :'?', _) do
    {[], []}
  end

  defp is_flag(<<pc, _ :: binary>>, pc) do
    true
  end
  defp is_flag(_, _) do
    false
  end
end
