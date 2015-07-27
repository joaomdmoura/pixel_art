defmodule PixelArt.PageController do
  use PixelArt.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def loaderio(conn, _params) do
    conn
    |> put_layout(false)
    |> render "loaderio.html"
  end
end
