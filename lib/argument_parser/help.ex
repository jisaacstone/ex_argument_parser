defmodule ArgumentParser.Help do
  @moduledoc :false

  @doc :false
  def describe(%ArgumentParser{} = parser) do
    """
    #{parser.description}
    #{format_body(parser)}
    #{parser.epilog}
    """ |> String.strip()
  end

  defp format_body(parser) do
    flags = if parser.add_help do
      parser.flags ++ [[:help, alias: :h, action: :help,
                        help: "Display this message and exit"]]
    else
      parser.flags
    end

    [ "Usage:",
      format_position_head(parser.positional),
      "\n",
      format_args(:positional, parser.positional),
      "\nOptions:\n",
      format_args(:flag, flags) ]
  end

  defp format_position_head([]) do
    []
  end
  defp format_position_head([[name | options] | rest]) do
    mv = format_metavars(
      Keyword.get(options, :action, :store),
      Keyword.get(options, :metavar, Atom.to_string(name)))
    [mv | format_position_head(rest)]
  end

  defp format_metavars(:store, mv) do
    [?\ , mv]
  end
  defp format_metavars(t, mv) when is_tuple(t) do
    format_metavars(elem(t, 1), mv)
  end
  defp format_metavars(n, mv) when is_number(n) do
    (for _ <- 1..n, do: "#{ mv}") |> Enum.join
  end
  defp format_metavars(:*, mv) do
    " [#{mv} ...]"
  end
  defp format_metavars(:+, mv) do
    " #{mv} [#{mv} ...]"
  end
  defp format_metavars(action, mv)
  when action in [:'?', :store_true, :store_false, :store_const] do
    " [#{mv}]"
  end
  defp format_metavars(_, _) do
    ""
  end

  defp longest_name(args) do
    Stream.map(args, &Kernel.hd/1) |>
      Stream.map(&Atom.to_string/1) |>
      Stream.map(&String.length/1) |>
      Enum.max()
  end

  defp format_args(_, []), do: ""
  defp format_args(type, args) do
    Enum.map(args, &format_arg(type, &1, longest_name(args)))
  end

  defp format_arg(:positional, [name | options], name_len) do
    [:io_lib.format('  ~-#{name_len}s', [name]), format_arg_help(options)]
  end
  defp format_arg(:flag, [name | options], name_len) do
    [ "  ",
      (if alias = options[:alias], do: "-#{alias} ", else: ""),
      :io_lib.format('--~-#{name_len}s', [name]),
      format_arg_help(options)]
  end

  defp format_arg_help(options) do
    [ if choices = Keyword.get(options, :choices) do
        "  one of #{inspect(choices)}"
      else "" end,
      if default = Keyword.get(options, :default) do
        "  default: #{default}"
      else "" end,
      if help = Keyword.get(options, :help) do
        "  #{help}"
      else "" end,
      "\n" ]
  end
end
