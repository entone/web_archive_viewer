defmodule WebArchiveViewer.Router do
  use Plug.Router
  import Plug.Conn

  require Logger

  alias WebArchiveViewer.Archives

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/search" do
    %{"q" => query} = conn.params

    case query do
      "" ->
        send_resp(conn, 200, Jason.encode!([]))

      query ->
        {:ok, res} = Archives.search(query)
        res = Enum.map(res, fn r -> Map.delete(r, :zip) end)
        send_json(conn, 200, Jason.encode!(res))
    end
  end

  get "/" do
    file =
      :web_archive_viewer
      |> :code.priv_dir()
      |> Path.join("templates/viewer.eex.html")
      |> File.read!()

    archives = Archives.get_all()
    Logger.info("#{inspect(archives)}")
    content = EEx.eval_string(file, archives: archives)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, content)
  end

  get "/archive/:id/:file_name" do
    Logger.info("Sending file #{file_name} from archive #{id}")
    archive = Archives.get(id)
    file = Archives.get_file(archive, file_name)

    conn
    |> send_resp(200, file)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def send_json(conn, code, content) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, content)
  end

  def send_html(conn, code, content) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(code, content)
  end
end
