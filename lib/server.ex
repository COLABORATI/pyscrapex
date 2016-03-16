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
  require Logger

  alias Downloader.Worker
  alias Downloader.Processor

  def start_link() do
    Logger.debug "main server starting..."
    GenServer.start_link(__MODULE__, %{urls: [], failed: []})
  end

  def download_urls(pid, urls) do
    GenServer.cast(pid, {:download, urls})
  end

  def has_work?(pid) do
    state = GenServer.call(pid, :get_state)
    length(state) > 0
  end

  def mark_as_done(pid, url) do
    Logger.debug "#{url} done"
    GenServer.call(pid, {:done, url})
  end
  def mark_as_failure(pid, url) do
    Logger.info "#{url} failed!"
    GenServer.call(pid, {:fail, url})
  end

  # Server part
  def init(state) do
    Logger.debug "main server started"
    Downloader.register_default(self)
    {:ok, state}
  end


  def handle_call({:done, url}, _from, state) do
    {:reply, :ok, %{state | urls: state[:urls] -- [url]}}
  end
  def handle_call({:fail, url}, _from, state) do
    {:reply, :ok, %{state | failed: state[:failed] ++ [url]}}
  end
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end


  def handle_cast({:download, urls}, state) do
    spawn_link(Downloader.Server, :batch_download, [self, urls])
    {:noreply, %{state | urls: state[:urls] ++ urls}}
  end

  def batch_download(server_pid, urls) do
    for url <- urls do
      spawn Downloader.Server, :do_page, [server_pid, url]
    end
  end

  def do_page(server_pid, url) do
    try do
      response = Pool.transaction :downloaders, do: Worker.download(worker, url)
      Pool.transaction :processors, do: Processor.process(worker, response)
    rescue
      _ ->
        mark_as_failure(server_pid, url)
    after
      mark_as_done(server_pid, url)
    end
  end

end


      # if String.contains? url, "50" do
      #   raise "error"
      # end
