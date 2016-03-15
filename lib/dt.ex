defmodule T do
  defmacro rep(arg, do: body) do
    tst = quote do
      fn () -> unquote(arg) end
    end
    quote do
      Stream.repeatedly(unquote(tst))
      |> Stream.take_while(&(!! &1))
      |> Enum.map( fn (x) -> unquote(body) end)
    end
  end
end
