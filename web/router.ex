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
  end
end
