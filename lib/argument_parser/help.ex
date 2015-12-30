defmodule ArgumentParser.Help do
  @moduledoc :false

  @doc :false
  def describe(%ArgumentParser{} = parser) do
    """
    #{parser.description}
    #{print_body(parser)}
    #{parser.epilog}
    """ |> String.strip()
  end

  defp print_body(parser) do
    flags = if parser.add_help do
      parser.flags ++ [[:help, alias: :h, action: :help,
                        help: "Display this message and exit"]]
    else
      parser.flags
    end

    [ "Usage: ",
      print_position_head(parser.positional),
      "\n",
      Enum.map(parser.positional, &print_positional/1),
      "\nOptions:\n",
      Enum.map(flags, &print_flag/1) ]
  end

  defp print_position_head([]) do
    []
  end
  defp print_position_head([[name_a | options] | rest]) do
    name = Atom.to_string(name_a)
    mv = print_metavars(
      Keyword.get(options, :action, :store),
      Keyword.get(options, :metavar, String.upcase(name)))
    text = if options[:required] do
      [name, mv, " "]
    else
      ["[", name, mv, "] "]
    end
    [text, print_position_head(rest)]
  end

  defp print_metavars(:store, mv) do
    mv
  end
  defp print_metavars(t, mv) when is_tuple(t) do
    print_metavars(elem(t, 1), mv)
  end
  defp print_metavars(n, mv) when is_number(n) do
    (for _ <- 1..n, do: "#{ mv}") |> Enum.join
  end
  defp print_metavars(:*, mv) do
    " [#{mv} ...]"
  end
  defp print_metavars(:+, mv) do
    " #{mv} [#{mv} ...]"
  end
  defp print_metavars(:'?', mv) do
    " [#{mv}]"
  end
  defp print_metavars(_, _) do
    ""
  end

  defp print_positional([name | options]) do
    ["\t#{name}", print_arg_help(options)]
  end

  defp print_flag([name | options]) do
    [ "\t--#{name}",
      (if alias = options[:alias], do: " -#{alias}", else: ""),
      print_arg_help(options) ]
  end

  defp print_arg_help(options) do
    [ if choices = Keyword.get(options, :choices) do
        " one of #{inspect(choices)}"
      else "" end,
      if default = Keyword.get(options, :default) do
        " default: #{default}"
      else "" end,
      if help = Keyword.get(options, :help) do
        " #{help}"
      else "" end,
      "\n" ]
  end
end
