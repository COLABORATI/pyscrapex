defmodule Downloader.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def download(worker, url) do
    GenServer.call(worker, {:download, url})
  end

  def handle_call({:download, url}, _from, state) do
    response = HTTPoison.get!(url)
    {:reply, response, state}
  end
end
