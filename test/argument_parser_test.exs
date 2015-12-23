defmodule ArgumentParserTest do
  use ExUnit.Case
  doctest ArgumentParser

  test "positional" do
    parser = ArgumentParser.new(positional: [[:foo]])
    assert(ArgumentParser.parse(parser, ["bar"]) == {:ok, %{foo: "bar"}})
  end

  test "flags" do
    parser = ArgumentParser.new(flags: [[:foo, alias: :f], [:bar, alias: :b]])
    {:ok, parsed} = ArgumentParser.parse(parser, ~w[-f baz --bar biz])
    assert(parsed == %{foo: "baz", bar: "biz"})
  end

  test "nargs" do
    flags = [
      [:three,  action: {:store, 3}],
      [:star,   action: {:store, :*}],
      [:plus,   action: {:store, :+}],
      [:remain, action: {:store, :remainder}]]
    parser = ArgumentParser.new(flags: flags)

    {:ok, parsed} = ArgumentParser.parse(parser, ~w[--three baz bar biz])
    assert(parsed == %{three: ["baz", "bar", "biz"]})

    {:ok, parsed} = ArgumentParser.parse(parser, ~w[--star baz bar])
    assert(parsed == %{star: ["baz", "bar"]})

    {:ok, parsed} = ArgumentParser.parse(parser, ~w[--plus baz bar])
    assert(parsed == %{plus: ["baz", "bar"]})

    {:ok, parsed} = ArgumentParser.parse(parser, ~w[--star one --remain two --plus three])
    assert(parsed == %{star: ["one"], remain: ["two", "--plus", "three"]})
  end

  test "convert" do
    args = [[:hex,   action: {:store, &String.to_integer(&1, 16)}],
            [:atoms, action: {:store, :*, &String.to_atom/1}]]
    parser = ArgumentParser.new(positional: args)
    {:ok, parsed} = ArgumentParser.parse(parser, ~w[539 one two])
    assert(parsed == %{hex: 1337, atoms: [:one, :two]})
  end

  test "store const" do
    flags = [
      [:store_true_set,    alias: :t, action: :store_true],
      [:store_false_set,   alias: :f, action: :store_false],
      [:store_const_set,   alias: :c, action: {:store_const, {:yes, [7]}}],
      [:store_true_unset,  alias: :x, action: :store_true],
      [:store_false_unset, alias: :y, action: :store_false],
      [:store_const_unset, alias: :z, action: {:store_const, :no}]]
    parser = ArgumentParser.new(flags: flags)
    {:ok, parsed} = ArgumentParser.parse(parser, ["-tcf"])
    assert(parsed == %{store_true_set:    true,
                       store_true_unset:  false,
                       store_false_set:   false,
                       store_false_unset: true,
                       store_const_set:   {:yes, [7]}})
  end

  test "default" do
    parser = ArgumentParser.new(flags: [[:foo, default: :barbeque]])
    assert(ArgumentParser.parse(parser, []) == {:ok, %{foo: :barbeque}})
  end

  test "count" do
    parser = ArgumentParser.new(flags: [[:count, alias: :c, action: :count]])
    assert(ArgumentParser.parse(parser, []) == {:ok, %{count: 0}})
    assert(ArgumentParser.parse(parser, ["--count"]) == {:ok, %{count: 1}})
    assert(ArgumentParser.parse(parser, ["-ccc"]) == {:ok, %{count: 3}})
  end
end
