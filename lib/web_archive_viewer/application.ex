defmodule WebArchiveViewer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger
  alias WebArchiveViewer.Router

  def start(_type, _args) do
    port = Application.get_env(:web_archive_viewer, :http_port) || 4000
    path = System.get_env("ARCHIVE_PATH")

    children = [
      {WebArchiveViewer.Archives, path: path},
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: port, compress: true]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebArchiveViewer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
