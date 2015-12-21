defmodule ArgumentParserErrorTest do
  use ExUnit.Case

  test "positional" do
    parser = ArgumentParser.new(positional: [[:foo]])
    {:error, message} = ArgumentParser.parse(parser, ["bar", "baz"], :false)
    assert(message =~ "unexpected argument: baz")
  end

  test "flag" do
    {:error, message} = ArgumentParser.parse(
      ArgumentParser.new(), ["--foo"], :false)
    assert(message =~ "unexpected flag: foo")
  end

  test "alias" do
    {:error, message} = ArgumentParser.parse(
      ArgumentParser.new(), ["-f"], :false)
    assert(message =~ "unexpected flag: f")
  end
end
