defmodule DlTools do
  def repeat(fun, times) do
    (0 .. (times - 1)) |> Enum.map fn (_) -> fun.() end
  end
end

defmodule Downloader.Details do
  alias HTTPoison.Response, as: Response

  def get!(url) do
    {res, resp} = get(url)
    case resp do
      %Response{body: html} -> html
      _ -> ""
    end
  end

  def get(url) do
    HTTPoison.get url
  end
end


defmodule Downloader.Writer do
  alias Downloader.Urls, as: Urls

  def save(url, blob) do
    IO.inspect ["!!save!! running", url]
    File.write(Urls.to_name(url), blob)
  end

  def _saver() do
    fn ({a, b}) -> save(a, b) end
  end
end
