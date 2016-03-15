defmodule Downloader.Urls do
  import PatternTap

  @directory_url "http://mangafox.me/manga/"
  @base_path "data/"            # directory to download to

  # Public API
  def to_name(url) do
    String.split(url, "/")
    |> Enum.filter(fn
                     ("") -> false;
                     (_)  -> true
                   end)
    |> List.last
    |> prefix_path
  end

  def get_chunked(), do: get() |> Enum.chunk 10

  def get() do
    resp = HTTPoison.get! @directory_url
    Floki.find(resp.body, "a.series_preview") |> get_addresses
  end


 # Private API
  # ----------------------------------------------------------------------------
  defp get_addresses(elems) do
    f = fn ({_, attrs, _}) ->
      List.keyfind(attrs, "href", 0) |> tap({_, href} ~> href)
    end
    Enum.map elems, f
  end

  defp prefix_path(nil), do: ""
  defp prefix_path(fname), do: @base_path <> fname
end

defmodule Mangaupdates do
  use PatternTap
  def get_page(num) do
    HTTPoison.get!("http://www.mangaupdates.com/categories.html?page=" <> num <> "&perpage=100").body
  end

  def is_category_link?({_, attrs, _}) do
    List.keyfind(attrs, "href", 0)
    |> tap({_, a} ~> a)
    |> String.contains?("category")
  end

  def categories_list do
    File.read!("baka-updates.dump") |> :erlang.binary_to_term
  end

  def start do
    # categories_list = for p <- 1..38 do
    #   IO.inspect(p)
    #   get_page(Integer.to_string p)
    #   |> Floki.find("a")
    #   |> Enum.filter(&is_category_link?/1)
    #   |> Enum.map(&clean/1)
    # end

    categories_list |> List.flatten |> Enum.filter(&not_b/1)
  end


  def get_all() do
    Mangaupdates.start
    |> Enum.map(  &(:erlang.element 1, &1) )
    |> Enum.filter( &Mangaupdates.not_b/1 )
  end


  def not_b({"b", _, _}) do
    false
  end
  def not_b(_) do
    true
  end

 def clean({_, [{"href", href}], [txt]}) do
    {txt, href}
  end
end
