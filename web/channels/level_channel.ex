defmodule PixelArt.LevelChannel do
  use PixelArt.Web, :channel
  require Logger

  def join("levels", payload, socket) do
    {:ok, socket}
  end

  def handle_in("moved", payload, socket) do
    broadcast! socket, "moved", %{id: payload["id"], direction: payload["direction"], position: payload["cord"] }
    {:reply, {:ok, payload}, assign(socket, :user, payload)}
  end

  def handle_in("stop", payload, socket) do
    broadcast! socket, "stop", %{id: payload["id"]}
    {:reply, {:ok, payload}, assign(socket, :user, payload)}
  end

  def handle_in("logged", payload, socket) do
    broadcast! socket, "logged", %{id: payload["user"]}
    {:noreply, socket}
  end

  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end
end
