defmodule PixelArt.Router do
  use PixelArt.Web, :router

  socket "/ws", PixelArt do
    channel "levels", LevelChannel
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  scope "/", PixelArt do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/loaderio-dba90f34b1aea2c4c24db9c1d75fe77e", PageController, :loaderio
  end
end
