defmodule WebArchiveViewer.Search do
  @moduledoc false

  alias Sonix.Modes.Ingest
  require Logger

  @limit 100

  def suggest(col, b, pwd, text) do
    conn = start("search", pwd)
    res = Sonix.suggest(conn, col, b, text)
    Sonix.quit(conn)
    res
  end

  def search(col, b, pwd, text) do
    conn = start("search", pwd)
    res = Sonix.query(conn, col, b, text, limit: @limit)
    Sonix.quit(conn)
    res
  end

  def push(col, b, pwd, {id, chunks}) when is_list(chunks) do
    conn = start("ingest", pwd)

    Enum.each(chunks, fn chunk ->
      Ingest.push(conn, col, b, id, chunk)
    end)

    Sonix.quit(conn)
  end

  def push(col, b, pwd, {id, text}) do
    push(col, b, pwd, {id, [text]})
  end

  def start(mode, pwd) do
    host = System.get_env("SEARCH_HOST")
    port = System.get_env("SEARCH_PORT")

    case Sonix.init(host, port) do
      {:error, :closed} ->
        Logger.info("Can't connect to search server at localhost:1491 retrying...")
        :timer.sleep(1000)
        start(mode, pwd)

      {:ok, conn} ->
        {:ok, conn} = Sonix.start(conn, mode, pwd)
        conn
    end
  end
end
