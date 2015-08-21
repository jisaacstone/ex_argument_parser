defmodule ArgumentParserErrorTest do
  use ExUnit.Case

  test "positional" do
    parser = %ArgumentParser{positional: [[:foo]]}
    {:error, message} = ArgumentParser.parse(["bar", "baz"], parser)
    assert(message =~ "unexpected argument: baz")
  end

  test "flag" do
    {:error, message} = ArgumentParser.parse(["--foo"], %ArgumentParser{})
    assert(message =~ "unexpected flag: foo")
  end

  test "alias" do
    {:error, message} = ArgumentParser.parse(["-f"], %ArgumentParser{})
    assert(message =~ "unexpected flag: f")
  end
end
