defmodule Downloader do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, []) do
    downloader_pool = [
      name: {:local, :downloaders},
      worker_module: Downloader.Worker,
      size: 10, max_overflow: 1
    ]
    processor_pool = [
      name: {:local, :processors},
      worker_module: Downloader.Processor,
      size: 4, max_overflow: 1
    ]
    initial_state = nil
    children = [
      :poolboy.child_spec(:processors, processor_pool, initial_state),
      :poolboy.child_spec(:downloaders, downloader_pool, initial_state),
      worker(Agent, [fn -> nil end, [name: :default_downloader]]),
      worker(Downloader.Server, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one,
                                    name: Downloader.Supervisor)
  end

  def register_default(pid) do
    Agent.update(:default_downloader, fn (_) -> pid end)
  end
  def get_default() do
    Agent.get(:default_downloader, fn (x) -> x end)
  end

  def download_urls(urls) do
    Downloader.Server.download_urls(get_default(), urls)
  end

  def main() do
    1 .. 100
    |> Enum.map(fn (i) -> "http://localhost/?#{i}" end)
    |> Enum.to_list |> download_urls
  end
end
