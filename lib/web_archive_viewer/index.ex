defmodule WebArchiveViewer.Index do
  import Meeseeks.CSS

  require Logger

  @tags ~w(p blockquote strong h1 h2 h3)

  @buffer 19_900

  @non_words ~r/\W/ux

  def run(title, host, content) do
    content
    |> Meeseeks.parse()
    |> extract_text()
    |> extract_image_alt()
    |> add_text(title)
    |> add_text(host)
    |> clean_text()
    |> chunk()
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

  def chunk(content) do
    {:ok, get_chunks(content)}
  end

  def get_chunks(content, chunks \\ []) do
    {chunk, rest} = split_at_space(content)
    chunks = [chunk | chunks]

    case rest do
      "" -> chunks
      rest -> get_chunks(rest, chunks)
    end
  end

  def split_at_space(content) when is_binary(content) do
    words = String.split(content, " ")

    Enum.reduce_while(words, {"", 0}, fn word, {chunk, count} ->
      new = chunk <> " " <> word

      case byte_size(new) < @buffer do
        true -> {:cont, {new, count + 1}}
        false -> {:halt, {chunk, Enum.join(Enum.slice(words, count..-1), " ")}}
      end
    end)
  end

  def split_at_space(c), do: {c, ""}
end
