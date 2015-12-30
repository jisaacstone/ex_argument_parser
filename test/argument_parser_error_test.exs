defmodule ArgumnetParserErrorTest do
  use ExUnit.Case
  alias ArgumentParser, as: AP

  test "positional" do
    parser = AP.new(positional: [[:foo]])
    {:error, message} = AP.parse(parser, ["bar", "baz"], :false)
    assert(message =~ "unexpected argument: baz")
  end

  test "flag" do
    {:error, message} = AP.parse(
      AP.new(), ["--foo"], :false)
    assert(message =~ "unexpected flag: foo")
  end

  test "alias" do
    {:error, message} = AP.parse(
      AP.new(), ["-f"], :false)
    assert(message =~ "unexpected flag: f")
  end
end
