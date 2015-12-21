defmodule ArgumentParser.Parser do
  alias ArgumentParser, as: AP
  @moduledoc :false

  @narg_atoms [:'?', :*, :+, :remainder]

  @type result :: {:ok, Map.t} | {:error, term} | {:message, binary}

  @doc :false
  @spec parse([String.t], AP.t) :: result
  def parse(args, %AP{} = parser) when is_list(args) do
    parse(args, parser, %{}) |> check_arguments(parser)
  end

  @spec check_arguments(result, AP.t) :: result
  # Check for required args and set defaults
  defp check_arguments({:ok, parsed}, parser) do
    missing_args = Stream.concat(parser.positional, parser.flags) |>
      Stream.map(fn(a) -> {a, key_for(a)} end) |>
      Stream.reject(&Dict.has_key?(parsed, elem(&1, 1)))
    Enum.reduce(missing_args, {:ok, parsed}, &check_argument/2)
  end
  defp check_arguments(other, _parser) do
    other
  end

  defp check_argument(_argument, {:error, reason}) do
    {:error, reason}
  end
  defp check_argument({argument, key}, {:ok, parsed}) do
    case Keyword.fetch(argument, :default) do
      {:ok, value} -> {:ok, Dict.put_new(parsed, key, value)}
      :error ->
        action = Keyword.get(argument, :action)
        cond do
          action == :count ->
            {:ok, Dict.put_new(parsed, key, 0)}
          action == :store_true ->
            {:ok, Dict.put_new(parsed, key, false)}
          action == :store_false ->
            {:ok, Dict.put_new(parsed, key, true)}
          Keyword.get(argument, :required) ->
            {:error, "missing required arg #{key}"}
          true ->
            {:ok, parsed}
        end
    end
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

  @spec parse([String.t], AP.t, Map.t) :: result
  defp parse([], _parser, parsed) do
    {:ok, parsed}
  end
  # -h
  defp parse([<<pc, ?h>> | parser],
             %{add_help: true, prefix_char: pc} = parser, _) do
    {:message, AP.print_help(parser)}
  end
  # --help
  defp parse([<<pc, pc, ?h, ?e, ?l, ?p>> | _],
             %{add_help: true, prefix_char: pc} = parser, _) do
    {:message, AP.print_help(parser)}
  end
  # --[flag]
  defp parse([<<pc, pc, arg :: binary>> | rest],
             %{prefix_char: pc} = parser,
             parsed) do
    get_flag_by_name(String.to_atom(arg), parser.flags, parser.strict) |>
      apply_argument(rest, parsed, parser) |>
      check_if_done(parser)
  end
  # -[alias]+ (e.g. -aux -> -a -u -x)
  defp parse([<<pc, aliased :: binary>> | rest],
             %{prefix_char: pc} = parser,
             parsed) do
    unalias_and_apply(aliased, rest, parsed, parser) |>
      check_if_done(parser)
  end
  # positional args
  defp parse(args,
             %{positional: [head | tail]} = parser,
             parsed) do
    apply_argument(head, args, parsed, parser) |>
      check_if_done(%{parser | positional: tail})
  end
  # unexpected positional arg
  defp parse([head | tail], parser, parsed) do
    if parser.strict do
      {:error, "unexpected argument: #{head}"}
    else
      parse(tail, parser, Dict.put(parsed, String.to_atom(head), true))
    end
  end

  defp check_if_done({:ok, args, parsed}, parser) do
    parse(args, parser, parsed)
  end
  defp check_if_done(other, _parser) do
    other
  end

  defp apply_argument({:error, _} = err, _, _, _) do
    err
  end
  defp apply_argument(argument, args, parsed, parser) do
    key = key_for(argument)
    Keyword.get(argument, :action, :store) |>
      apply_action(args, key, parsed, parser) |>
      check_choices({Dict.get(argument, :choices), key})
  end

  defp check_choices({:ok, args, parsed}, {choices, key})
  when is_list(choices) do
    if parsed[key] in choices do
      {:ok, args, parsed}
    else
      {:error, "value for #{key} should be one of #{
               inspect(choices)}, got #{parsed[key]}"}
    end
  end
  defp check_choices(result, _) do
    result
  end

  defp apply_action(action, _, key, %{key: _}, _)
  when (is_atom(action) and action != :append)
  or (is_tuple(action) and not elem(action, 0) in [:append, :append_const]) do
    {:error, "duplicate key #{key}"}
  end
  defp apply_action(:store, [head | args], key, parsed, _parser) do
    {:ok, args, Dict.put(parsed, key, head)}
  end
  defp apply_action({:store, f}, [head | args], key, parsed, _parser)
  when is_function(f) do
    {:ok, args, Dict.put(parsed, key, f.(head))}
  end
  defp apply_action({:store, n}, args, key, parsed, parser)
  when is_number(n) or n in @narg_atoms do
    {value, rest} = fetch_nargs(args, n, parser)
    {:ok, rest, Dict.put_new(parsed, key, value)}
  end
  defp apply_action({:store, n, f}, args, key, parsed, parser)
  when is_function(f) and (is_number(n) or n in @narg_atoms) do
    {value, rest} = fetch_nargs(args, n, parser)
    newvalue = if is_list(value) do
      Enum.map(value, f)
    else
      f.(value)
    end
    {:ok, rest, Dict.put_new(parsed, key, newvalue)}
  end
  defp apply_action(:store_true, args, key, parsed, _parser) do
    {:ok, args, Dict.put_new(parsed, key, true)}
  end
  defp apply_action(:store_false, args, key, parsed, _parser) do
    {:ok, args, Dict.put_new(parsed, key, false)}
  end
  defp apply_action({:store_const, const}, args, key, parsed, _parser) do
    {:ok, args, Dict.put_new(parsed, key, const)}
  end
  defp apply_action(:append, [head | args], key, parsed, _parser) do
    {:ok, args, Dict.update(parsed, key, [head], &([head | &1]))}
  end
  defp apply_action({:append, f}, [head | args], key, parsed, _parser)
  when is_function(f) do
    value = f.(head)
    {:ok, args, Dict.update(parsed, key, [value], &([value | &1]))}
  end
  defp apply_action({:append, n}, args, key, parsed, parser)
  when is_number(n) or n in @narg_atoms do
    case fetch_nargs(args, n, parser) do
      {:error, reason} -> {:error, reason}
      {value, rest} ->
        {:ok, rest, Dict.update(parsed, key, [value], &([value | &1]))}
    end
  end
  defp apply_action({:append, n, f}, args, key, parsed, parser)
  when is_function(f) and (is_number(n) or n in @narg_atoms) do
    case fetch_nargs(args, n, parser) do
      {:error, reason} -> {:error, reason}
      {value, rest} ->
        {:ok, rest, Dict.update(parsed, key, [value], &([value | &1]))}
    end
  end
  defp apply_action({:append_const, const, key}, args, _key, parsed, _parser) do
    {:ok, args, Dict.update(parsed, key, [const], &([const | &1]))}
  end
  defp apply_action(:count, args, key, parsed, _parser) do
    {:ok, args, Dict.update(parsed, key, 1, &(&1 + 1))}
  end
  defp apply_action(:help, _, _, _, parser) do
    {:message, AP.print_help(parser)}
  end
  defp apply_action({:version, version}, _, _, _, _) do
    {:message, version}
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
      {:ok, [rest | args], parsed} ->
        # sometimes alias flags are grouped together: -frt == -f -r -t
        unalias_and_apply(rest, args, parsed, parser)
      result ->
        # sometimes it is a single alias with a value: -frf == --foo rt
        result
    end
  end

  defp get_flag_by_name(name, arguments, strict) do
    get_flag(name, arguments, strict, &hd/1)
  end
  defp get_flag_by_alias(name, arguments, strict) do
    get_flag(name, arguments, strict, &Keyword.get(&1, :alias))
  end
  defp get_flag(ident, [], true, _) do
    {:error, "unexpected flag: #{ident}"}
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


  defp fetch_nargs(args, n, _parser) when is_number(n) do
    Enum.split(args, n)
  end
  defp fetch_nargs(args, :remainder, _parser) do
    {args, []}
  end
  defp fetch_nargs(args, :*, parser) do
    Enum.split_while(args, &(not flag?(&1, parser.prefix_char)))
  end
  defp fetch_nargs(args, :+, parser) do
    case Enum.split_while(args, &(not flag?(&1, parser.prefix_char))) do
      {[], _} -> {:error, "Missing value"}
      result  -> result
    end
  end
  defp fetch_nargs([head | tail] = args, :'?', parser) do
    if flag?(head, parser.prefix_char) do
      {[], args}
    else
      {head, tail}
    end
  end
  defp fetch_nargs([], :'?', _) do
    {[], []}
  end

  defp flag?(<<pc, _ :: binary>>, pc) do
    true
  end
  defp flag?(_, _) do
    false
  end
end
