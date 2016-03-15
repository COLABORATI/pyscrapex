defmodule Downloader.Main do
  alias Downloader.Writer, as: Writer
  alias Downloader.Urls, as: Urls
  alias Downloader.Details, as: Details

  import DlTools

  @wait_for 10_000              # wait this long between batch downloads

  # External API
  def start(n \\ 10) do
    addresses = case n do
      :inf -> Urls.get_chunked()
      x    -> Urls.get_chunked() |> Enum.take(x)
    end

    main_loop(addresses)
  end

  # Internals
  def main_loop(addresses) do
    for chunk <- addresses do
      receive do after @wait_for -> nil end
      try do
        fetch_all(chunk) |> Enum.each(Writer._saver)
      rescue
        _ -> nil
      end
    end
  end

  def fetch_all(pages) do
    for url <- pages, do: spawn_link _fetcher(self(), url)
    repeat(&recv_response/0, length(pages))
  end

  def recv_response() do
    receive do
      {url, html} = resp -> resp
    after 5_000 ->
        raise "resp timeout"
    end
  end

  def _fetcher(pid, url) do
    fn () ->
      send pid, {Urls.to_name(url),
                 # makes actual HTTP request:
                 Details.get!(url)}
    end
  end
end
