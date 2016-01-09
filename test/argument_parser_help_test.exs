defmodule ArgumentParser.Help.Test do
  alias ArgumentParser, as: AP
  use ExUnit.Case, async: :true

  test "description" do
    msg = AP.new(description: "Kirkland Singature") |> AP.print_help()
    assert String.contains?(msg, "Kirkland Singature"), msg
  end

  test "epilog" do
    msg = AP.new(epilog: "Mixed Nuts") |> AP.print_help()
    assert String.contains?(msg, "Mixed Nuts"), msg
  end

  test "arg help" do
    msg = AP.new() |>
      AP.add_arg(:foo, help: "do a foo") |>
      AP.print_help()
    assert String.contains?("#{msg}", "do a foo"), msg
  end

  test "position head" do
    msg = AP.new() |>
      AP.add_arg(:foo, []) |>
      AP.add_arg(:bar, action: :store_true) |>
      AP.add_arg(:buzz, action: {:store, :*}) |>
      AP.print_help()
    assert String.contains?(msg, "Usage: foo [bar] [buzz ...]\n"), msg
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
    assert String.contains?(msg, "Usage: foo [bar] buzz [buzz ...]\n"), msg
  end
end
