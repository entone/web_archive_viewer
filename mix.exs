defmodule WebArchiveViewer.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_archive_viewer,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WebArchiveViewer.Application, []}
    ]
  end

  defp deps do
    [
      {:eex_html, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:meeseeks, "~> 0.14.0"},
      {:plug_cowboy, "~> 2.1"},
      {:sonix, github: "imerkle/sonix", tag: "1691c76e2167c7090f6d924d8c030ac448fd7b67"}
    ]
  end
end
