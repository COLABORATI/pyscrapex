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
      worker(Agent, [fn () -> [] end, [name: Dn]]),
      worker(Downloader.Server, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one,
                                    name: Downloader.Supervisor)
  end

  def main() do
    urls = 1 .. 100
    |> Enum.map(fn (_n) -> "http://localhost" end)
    |> Enum.to_list
    pid = Agent.get(Dn, fn (x) -> x end)
    Downloader.Server.download_urls(pid, urls)
  end
end

defmodule Downloader.Worker do
  use GenServer

  def start_link(nil) do
    GenServer.start_link(__MODULE__, nil)
  end

  def download(worker, url) do
    GenServer.call(worker, {:download, url})
  end

  def handle_call({:download, url}, _from, state) do
    IO.inspect {self(), url}
    res = HTTPoison.get!(url)
    {:reply, res, state}
  end
end

defmodule Downloader.Processor do
  use GenServer
  alias Application, as: App

  def start_link(nil) do
    priv_path = App.app_dir(:downloader, "priv") |> to_char_list
    {:ok, python} = :python.start(python_path: priv_path)
    GenServer.start_link(__MODULE__, python)
  end

  def process(processor_pid, http_response) do
    GenServer.call(processor_pid, convert_response(http_response))
  end

  def handle_call(http_response, _from, python) do
    :python.call(python, :worker, :process_response, [http_response])
    {:reply, :ok, python}
  end

  defp convert_response(http_response) do
    for {k, v} <- Map.to_list(http_response),  k != :__struct__ do
      {(Atom.to_string k), v}
    end
  end
end
