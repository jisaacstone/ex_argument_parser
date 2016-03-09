defmodule ArgumentParser.Help.Test do
  alias ArgumentParser, as: AP
  use ExUnit.Case, async: :true

  defmacrop contains(msg, string) do
    quote do
      assert(String.contains?(unquote(msg), unquote(string)),
             ~s("#{unquote(string)}" not found in message:\n#{unquote(msg)}))
    end
  end

  test "description" do
    msg = AP.new(description: "Kirkland Singature") |> AP.print_help()
    contains(msg, "Kirkland Singature")
  end

  test "epilog" do
    msg = AP.new(epilog: "Mixed Nuts") |> AP.print_help()
    contains(msg, "Mixed Nuts")
  end

  test "arg help" do
    msg = AP.new() |>
      AP.add_arg(:foo, help: "do a foo") |>
      AP.print_help()
    contains("#{msg}", "do a foo")
  end

  test "position head" do
    msg = AP.new() |>
      AP.add_arg(:foo, []) |>
      AP.add_arg(:bar, action: :store_true) |>
      AP.add_arg(:buzz, action: {:store, :*}) |>
      AP.print_help()
    contains(msg, "Usage: foo [bar] [buzz ...]\n")
  end

  test "position head macro" do
    defmodule PHM do
      use ArgumentParser.Builder
      @arg [:foo]
      @arg [:bar, action: :store_false]
      @arg [:buzz, action: {:store, :+}]
      def help() do
        {:message, msg} = parse(["-h"], :false)
        msg
      end
    end
    msg = PHM.help()
    contains(msg, "Usage: foo [bar] buzz [buzz ...]\n")
  end

  test "arg messages" do
    msg = AP.new(add_help: :false) |>
      AP.add_arg(:foo, help: "fubar") |>
      AP.add_flag(:bar, alias: :b) |>
      AP.print_help()
    contains(msg, "  foo  fubar\n")
    contains(msg, "  -b --bar")
  end

  test "short message" do
    parser = AP.new(description: "NOPE") |>
      AP.add_arg(:foo, help: "NOPE") |>
      AP.add_flag(:goo, help: "NOPE")
    description = AP.Help.describe_short(parser) |> List.to_string()
    refute String.contains?(description, "NOPE"), description
    assert String.contains?(description, "--goo"), description
    assert String.contains?(description, "foo"), description
  end

  test "short message flag combine" do
    parser = AP.new() |>
      AP.add_flag(:ok, alias: :k) |>
      AP.add_flag(:hat, alias: :h) |>
      AP.add_flag(:cat, alias: :c) |>
      AP.add_flag([:what])
    description = AP.Help.describe_short(parser) |> List.to_string()
    assert String.contains?(description, "-khc"), description
    assert String.contains?(description, "--what"), description
  end
end
