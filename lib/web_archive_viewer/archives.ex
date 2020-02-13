defmodule WebArchiveViewer.Archives do
  use GenServer

  require Logger

  @poll_interval 60_000

  def start_link(path: path) do
    GenServer.start_link(__MODULE__, path, name: __MODULE__)
  end

  def get_all() do
    GenServer.call(__MODULE__, :get)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get_id, id})
  end

  def get_file(archive, name) do
    GenServer.call(__MODULE__, {:get_file, archive, name})
  end

  def init(path) do
    Process.send_after(self(), :get_archives, @poll_interval)
    {:ok, %{archives: get_archives(path), path: path}}
  end

  def handle_call(:get, _from, %{archives: a} = state), do: {:reply, a, state}

  def handle_call({:get_id, id}, _from, %{archives: a} = state),
    do: {:reply, Map.get(a, id), state}

  def handle_call({:get_file, archive, name}, _from, state) do
    file = find_file(archive, name)
    {:ok, {_, data}} = :zip.zip_get(String.to_charlist(file.name), archive.zip)
    {:reply, data, state}
  end

  def handle_info(:get_archives, %{path: path} = state) do
    Process.send_after(self(), :get_archives, @poll_interval)
    {:noreply, %{state | archives: get_archives(path)}}
  end

  defp get_archives(path) do
    path
    |> list_archives()
    |> expand_archives()
  end

  defp find_file(archive, name) do
    Enum.find(archive.entries, fn %{name: file_name} ->
      String.ends_with?(file_name, name)
    end)
  end

  def expand_archives(archives) do
    Enum.reduce(archives, %{}, fn a, acc ->
      n = String.to_charlist(Path.join(a.path, a.filename))
      {:ok, zip} = :zip.zip_open(n, [:memory])
      {:ok, [_ | [dir | entries]]} = :zip.zip_list_dir(zip)
      {:zip_file, name, _fi, _, _, _} = dir
      name = String.slice(to_string(name), 0..-2)
      entries = expand_archive(entries)
      [e | _] = entries
      a = Map.put(a, :modified, e.modified)
      a = Map.put(a, :zip, zip)
      a = Map.put(a, :entries, entries)
      Map.put(acc, name, a)
    end)
  end

  def expand_archive(entries) do
    Enum.map(entries, fn
      {:zip_file, n,
       {:file_info, _, _t, _a, _at, mtime, _ct, _m, _l, _mjrd, _mnrd, _in, _uid, _gid}, _comment,
       _offset, _comp_size} ->
        %{name: to_string(n), modified: NaiveDateTime.from_erl!(mtime)}
    end)
  end

  def get_date([]), do: DateTime.utc_now()
  def get_date([%{info: %{mtime: d}} | _]), do: d

  def list_archives(path) do
    Enum.flat_map(File.ls!(path), fn p ->
      file = Path.join(path, p)

      case File.dir?(file) do
        true -> list_archives(file)
        false -> get_file(file)
      end
    end)
  end

  def get_file(file) do
    case String.ends_with?(file, ".maff") do
      true -> [parse_filename(file)]
      false -> []
    end
  end

  def parse_filename(file) do
    filename = Path.basename(file)

    [__ | host] =
      String.split(filename, "_") |> List.last() |> String.split(".") |> Enum.reverse()

    host = host |> Enum.reverse() |> Enum.join(".") |> String.trim()
    [_ | title] = filename |> String.split("_") |> Enum.reverse()
    title = title |> Enum.reverse() |> Enum.join(" ") |> String.trim()
    %{host: host, title: title, filename: filename, path: Path.dirname(file)}
  end
end
