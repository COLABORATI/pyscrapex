defmodule Ext do
  def format_self() do
    format_pid(self())
  end

  def format_pid(pid) when is_pid(pid) do
    :erlang.pid_to_list(pid) |> List.to_string
  end
end

defmodule Downloader.Processor do
  use GenServer
  require Logger

  alias Application, as: App

  def start_link(_args) do
    priv_path = App.app_dir(:downloader, "priv") |> to_char_list
    GenServer.start_link(__MODULE__, priv_path)
  end

  def process(processor_pid, http_response) do
    Logger.debug "Started processing response #{Ext.format_self}"
    GenServer.call(processor_pid, convert_resp(http_response))
  end

  def init(python_path) do
    :python.start_link(python_path: python_path)
  end

  def handle_call(http_response, _from, python) do
    :python.call(python, :worker, :process_response, [http_response])
    Logger.debug "Finished processing response #{Ext.format_self}"
    {:reply, :ok, python}
  end

  defp convert_resp(http_response) do
    for {k, v} <- Map.to_list(http_response),  k != :__struct__ do
      {(Atom.to_string k), v}
    end
  end
end
