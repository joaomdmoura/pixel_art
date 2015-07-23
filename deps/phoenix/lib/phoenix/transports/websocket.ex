defmodule Phoenix.Transports.WebSocket do
  use Plug.Builder
  require Logger

  import Phoenix.Controller, only: [endpoint_module: 1, router_module: 1]

  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Reply

  @moduledoc """
  Handles WebSocket clients for the Channel Transport layer.

  ## Configuration

  By default, JSON encoding is used to broker messages to and from clients,
  but the serializer is configurable via the Endpoint's transport configuration:

      config :my_app, MyApp.Endpoint, transports: [
        websocket_serializer: MySerializer
      ]

  The `websocket_serializer` module needs only to implement the `encode!/1` and
  `decode!/2` functions defined by the `Phoenix.Transports.Serializer` behaviour.

  Websockets, by default, do not timeout if the connection is lost. To set a
  maximum timeout duration in milliseconds, add this to your Endpoint's transport
  configuration:

      config :my_app, MyApp.Endpoint, transports: [
        websocket_timeout: 60000
      ]
  """

  alias Phoenix.Channel.Transport

  plug :check_origin
  plug :upgrade

  def upgrade(%Plug.Conn{method: "GET"} = conn, _) do
    put_private(conn, :phoenix_upgrade, {:websocket, __MODULE__}) |> halt
  end

  @doc """
  Handles initalization of the websocket.
  """
  def ws_init(conn) do
    Process.flag(:trap_exit, true)
    endpoint   = endpoint_module(conn)
    serializer = Dict.fetch!(endpoint.config(:transports), :websocket_serializer)
    timeout    = Dict.fetch!(endpoint.config(:transports), :websocket_timeout)

    {:ok, %{router: router_module(conn),
            endpoint: endpoint,
            sockets: HashDict.new,
            sockets_inverse: HashDict.new,
            serializer: serializer}, timeout}
  end

  @doc """
  Receives JSON encoded `%Phoenix.Socket.Message{}` from client and dispatches
  to Transport layer.
  """
  def ws_handle(opcode, payload, state) do
    msg = state.serializer.decode!(payload, opcode)

    case Transport.dispatch(msg, state.sockets, self, state.router, state.endpoint, __MODULE__) do
      {:ok, socket_pid} ->
        {:ok, put(state, msg.topic, socket_pid)}
      :ok ->
        {:ok, state}
      {:error, _reason} ->
        {:ok, state} # We are assuming the error was already logged elsewhere.
    end
  end

  def ws_info({:EXIT, socket_pid, reason}, state) do
    case HashDict.get(state.sockets_inverse, socket_pid) do
      nil   -> {:ok, state}
      topic ->
        new_state = delete(state, topic, socket_pid)

        case reason do
          :normal ->
            {:reply, state.serializer.encode!(Transport.chan_close_message(topic)), new_state}
          :shutdown ->
            {:reply, state.serializer.encode!(Transport.chan_close_message(topic)), new_state}
          {:shutdown, _} ->
            {:reply, state.serializer.encode!(Transport.chan_close_message(topic)), new_state}
          _other ->
            {:reply, state.serializer.encode!(Transport.chan_error_message(topic)), new_state}
        end
    end
  end

  def ws_info(%Message{} = message, %{serializer: serializer} = state) do
    {:reply, serializer.encode!(message), state}
  end

  def ws_info(%Reply{} = reply, %{serializer: serializer} = state) do
    %{topic: topic, status: status, payload: payload, ref: ref} = reply

    message = %Message{event: "phx_reply", topic: topic, ref: ref,
                       payload: %{status: status, response: payload}}

    {:reply, serializer.encode!(message), state}
  end

  def ws_info(_, state) do
    {:ok, state}
  end

  def ws_terminate(_reason, _state) do
    :ok
  end

  def ws_close(state) do
    for {pid, _} <- state.sockets_inverse do
      Phoenix.Channel.Server.close(pid)
    end
  end

  defp check_origin(conn, _opts) do
    Transport.check_origin(conn)
  end

  defp put(state, topic, socket_pid) do
    %{state | sockets: HashDict.put(state.sockets, topic, socket_pid),
              sockets_inverse: HashDict.put(state.sockets_inverse, socket_pid, topic)}
  end

  defp delete(state, topic, socket_pid) do
    %{state | sockets: HashDict.delete(state.sockets, topic),
              sockets_inverse: HashDict.delete(state.sockets_inverse, socket_pid)}
  end
end
