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
end
