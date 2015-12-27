defmodule APTest do
  use ExUnit.Case
  alias ArgumentParser, as: AP
  doctest AP

  test "positional" do
    parser = AP.new(positional: [[:foo]])
    assert(AP.parse(parser, ["bar"]) == {:ok, %{foo: "bar"}})
  end

  test "flags" do
    parser = AP.new(flags: [[:foo, alias: :f], [:bar, alias: :b]])
    {:ok, parsed} = AP.parse(parser, ~w[-f baz --bar biz])
    assert(parsed == %{foo: "baz", bar: "biz"})
  end

  test "nargs" do
    flags = [
      [:three,  action: {:store, 3}],
      [:star,   action: {:store, :*}],
      [:plus,   action: {:store, :+}],
      [:remain, action: {:store, :remainder}]]
    parser = AP.new(flags: flags)

    {:ok, parsed} = AP.parse(parser, ~w[--three baz bar biz])
    assert(parsed == %{three: ["baz", "bar", "biz"], star: []})

    {:ok, parsed} = AP.parse(parser, ~w[--star baz bar])
    assert(parsed == %{star: ["baz", "bar"]})

    {:ok, parsed} = AP.parse(parser, ~w[--plus baz bar])
    assert(parsed == %{plus: ["baz", "bar"], star: []})

    {:ok, parsed} = AP.parse(parser, ~w[--star one --remain two --plus three])
    assert(parsed == %{star: ["one"], remain: ["two", "--plus", "three"]})
  end

  test "convert" do
    args = [[:hex,   action: {:store, &String.to_integer(&1, 16)}],
            [:atoms, action: {:store, :*, &String.to_atom/1}]]
    parser = AP.new(positional: args)
    {:ok, parsed} = AP.parse(parser, ~w[539 one two])
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
    parser = AP.new(flags: flags)
    {:ok, parsed} = AP.parse(parser, ["-tcf"])
    assert(parsed == %{store_true_set:    true,
                       store_true_unset:  false,
                       store_false_set:   false,
                       store_false_unset: true,
                       store_const_set:   {:yes, [7]}})
  end

  test "default" do
    parser = AP.new(flags: [[:foo, default: :barbeque]])
    assert(AP.parse(parser, []) == {:ok, %{foo: :barbeque}})
  end

  test "count" do
    parser = AP.new(flags: [[:count, alias: :c, action: :count]])
    assert(AP.parse(parser, []) == {:ok, %{count: 0}})
    assert(AP.parse(parser, ["--count"]) == {:ok, %{count: 1}})
    assert(AP.parse(parser, ["-ccc"]) == {:ok, %{count: 3}})
  end

  test "append" do
    ap = AP.new() |> AP.add_flag(:a, action: :append)
    {:ok, res} = AP.parse(ap, [])
    assert res.a == []
    {:ok, res} = AP.parse(ap, ~w(--a 1 --a 2))
    assert res.a == ["1", "2"]
  end

  test "append convert" do
    {:ok, res} = AP.new() |>
      AP.add_flag(:a, action: {:append, &String.to_atom/1}) |>
      AP.parse(~w(--a foo --a bar))
    assert res.a == [:foo, :bar]
  end
end
