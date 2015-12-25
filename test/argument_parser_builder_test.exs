defmodule ArgumentParser.Builder.Test do
  use ExUnit.Case, async: :true

  test "using" do
    defmodule T do
      use ArgumentParser.Builder
      @arg [:foo]
      def t(args), do: parse(args)
    end

    {:ok, parsed} = T.t(["bar"])
    assert parsed[:foo] == "bar"
  end

  test "mix" do
    defmodule T.Mix do
      use ArgumentParser.Builder.Mix
      @flag [:poot, action: :store_true]

      def main(%{poot: :true}), do: "the truth!"
      def main(%{poot: :false}), do: "a lie!"
    end

    assert T.Mix.run(["--poot"]) == "the truth!"
    assert T.Mix.run([]) == "a lie!"
  end

  test "escript" do
    defmodule T.Escript do
      use ArgumentParser.Builder.Escript, prefix_char: ?7
      @flag [:goop, alias: :g]

      def run(parsed), do: parsed.goop
    end

    assert T.Escript.main(["7g--"]) == "--"
  end
end
