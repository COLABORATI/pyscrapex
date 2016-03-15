defmodule Pool do
  defmacro transaction(pool_name, do: block) do
    quote do
      :poolboy.transaction unquote(pool_name), fn (var!(worker)) ->
        unquote(block)
      end
    end
  end
end

defmodule Downloader.Server do
  use GenServer
  require Pool
  alias Downloader.Worker
  alias Downloader.Processor

  def start_link(), do:
    GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def has_work?(pid) do
    state = GenServer.call(pid, :get_state)
    length(state) > 0
  end


  # Server part
  def init(state) do
    pid = self()
    Agent.update(Dn, fn (_state) -> pid end)
    {:ok, state}
  end


  def download_urls(urls), do: download_urls(__MODULE__, urls)
  def download_urls(pid, urls) do
    GenServer.cast(pid, {:download, urls})
  end

  def handle_cast({:download, urls}, state) do
    spawn_link(download_fn(urls))
    {:noreply, state ++ urls}
  end

  defp download_fn(urls) do
    fn () ->
      for u <- urls do
        spawn_link(fn () ->
          response = Pool.transaction :downloaders,
            do: Worker.download(worker, u)
          result = Pool.transaction :processors,
            do: Processor.process(worker, response)
          GenServer.call(__MODULE__, {:done, u})
        end)
      end
    end
  end


  def handle_call({:done, url}, _from, state) do
    {:reply, :ok, state -- [url]}
  end
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
