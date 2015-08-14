defmodule ArgumentParserTest do
  use ExUnit.Case
  doctest ArgumentParser

  test "positional" do
    parser = %ArgumentParser{positional: [[:foo]]}
    assert(ArgumentParser.parse(["bar"], parser) == %{foo: "bar"})
  end

  test "flags" do
    parser = %ArgumentParser{flags: [[:foo, alias: :f], [:bar, alias: :b]]}
    parsed = ArgumentParser.parse(~w[-f baz --bar biz], parser)
    assert(parsed == %{foo: "baz", bar: "biz"})
  end

  test "nargs" do
    flags = [
      [:three, action: {:store, 3}],
      [:star,  action: {:store, :*}],
      [:plus,  action: {:store, :+}]]
    parser = %ArgumentParser{flags: flags}

    parsed = ArgumentParser.parse(~w[--three baz bar biz], parser)
    assert(parsed == %{three: ["baz", "bar", "biz"]})

    parsed = ArgumentParser.parse(~w[--star baz bar], parser)
    assert(parsed == %{star: ["baz", "bar"]})

    parsed = ArgumentParser.parse(~w[--plus baz bar], parser)
    assert(parsed == %{plus: ["baz", "bar"]})
  end

  test "convert" do
    args = [[:hex,   action: {:store, &String.to_integer(&1, 16)}],
            [:atoms, action: {:store, :*, &String.to_atom/1}]]
    parser = %ArgumentParser{positional: args}
    parsed = ArgumentParser.parse(~w[539 one two], parser)
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
    parser = %ArgumentParser{flags: flags}
    parsed = ArgumentParser.parse(["-tcf"], parser)
    assert(parsed == %{store_true_set:    true,
                       store_true_unset:  false,
                       store_false_set:   false,
                       store_false_unset: true,
                       store_const_set:   {:yes, [7]}})
  end

  test "default" do
    parser = %ArgumentParser{flags: [[:foo, default: :barbeque]]}
    assert(ArgumentParser.parse([], parser) == %{foo: :barbeque})
  end

  test "count" do
    parser = %ArgumentParser{flags: [[:count, alias: :c, action: :count]]}
    assert(ArgumentParser.parse([], parser) == %{count: 0})
    assert(ArgumentParser.parse(["--count"], parser) == %{count: 1})
    assert(ArgumentParser.parse(["-ccc"], parser) == %{count: 3})
  end
end
