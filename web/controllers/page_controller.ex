defmodule PixelArt.PageController do
  use PixelArt.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
