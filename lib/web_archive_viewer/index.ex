defmodule WebArchiveViewer.Index do
  import Meeseeks.CSS

  alias Sonix.Modes.Ingest

  require Logger

  @tags ~w(p blockquote strong h1 h2 h3)

  @non_words ~r/\W/ux

  def run(collection, bucket, id, title, host, content) do
    content
    |> Meeseeks.parse()
    |> extract_text()
    |> extract_image_alt()
    |> add_text(title)
    |> add_text(host)
    |> clean_text()
    |> push(collection, bucket, id)
  end

  def clean_text(text) do
    Regex.replace(@non_words, text, " ")
  end

  def extract_image_alt({doc, content}) do
    t =
      doc
      |> Meeseeks.all(css("img"))
      |> Enum.map(&Meeseeks.attr(&1, "alt"))
      |> Enum.join(" ")

    content <> " " <> t
  end

  def extract_text(doc) do
    {doc,
     Enum.flat_map(@tags, fn tag ->
       doc
       |> Meeseeks.all(css(tag))
       |> Enum.map(&Meeseeks.text/1)
     end)
     |> Enum.join(" ")}
  end

  def add_text(base, prepend), do: base <> " " <> prepend

  def push(content, collection, bucket, id) do
    {:ok, conn} = Sonix.init()
    {:ok, conn} = Sonix.start(conn, "ingest", "SecretPassword")
    content = String.slice(content, 0..19_000)
    :ok = Ingest.push(conn, collection, bucket, id, content)
    :ok = Sonix.quit(conn)
    {:ok, content}
  end
end
