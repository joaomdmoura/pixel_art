defmodule PixelArt.PageController do
  use PixelArt.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def loaderio(conn, _params) do
    render conn, "loaderio-dba90f34b1aea2c4c24db9c1d75fe77e.html"
  end
end
