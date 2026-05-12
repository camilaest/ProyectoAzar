# lib/azar/notificador.ex
defmodule Azar.Notificador do
  use GenServer

  @name __MODULE__
  @archivo_historial "priv/notificaciones.json"

  # API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, @name))
  end

  def suscribir(jugador_id, pid \\ self()) do
    GenServer.cast(@name, {:suscribir, jugador_id, pid})
  end

  def desuscribir(jugador_id) do
    GenServer.cast(@name, {:desuscribir, jugador_id})
  end

  def notificar_nuevo_sorteo(sorteo) do
    mensaje = "Nuevo sorteo creado: #{inspect(sorteo)}"
    GenServer.cast(@name, {:difundir, mensaje})
  end

  def notificar_cierre_sorteo(sorteo, resultados) do
    mensaje = "Sorteo cerrado: #{inspect(sorteo)}. Resultados: #{inspect(resultados)}"
    GenServer.cast(@name, {:difundir, mensaje})
  end

  def notificar_ganador(jugador_id, premio) do
    mensaje = "¡Felicidades! Ganaste el premio #{inspect(premio)}"
    GenServer.cast(@name, {:notificar_ganador, jugador_id, mensaje})
  end

  def obtener_historial(jugador_id) do
    GenServer.call(@name, {:obtener_historial, jugador_id})
  end

  # Callbacks
  def init(_opts) do
    historial = cargar_historial()
    {:ok, %{suscriptores: %{}, historial: historial}}
  end

  def handle_cast({:suscribir, jugador_id, pid}, state) do
    suscriptores = Map.put(state.suscriptores, jugador_id, pid)
    {:noreply, %{state | suscriptores: suscriptores}}
  end

  def handle_cast({:desuscribir, jugador_id}, state) do
    suscriptores = Map.delete(state.suscriptores, jugador_id)
    {:noreply, %{state | suscriptores: suscriptores}}
  end

  def handle_cast({:difundir, mensaje}, state) do
    now = ahora_colombia()

    nuevo_historial =
      Enum.reduce(state.suscriptores, state.historial, fn {jugador_id, pid}, hist ->
        if Process.alive?(pid) do
          enviar_notificacion(pid, mensaje)
        end

        actualizar_historial_en_mapa(hist, jugador_id, mensaje, now)
      end)

    persistir_historial(nuevo_historial)
    {:noreply, %{state | historial: nuevo_historial}}
  end

  def handle_cast({:notificar_ganador, jugador_id, mensaje}, state) do
    now = ahora_colombia()

    if pid = Map.get(state.suscriptores, jugador_id) do
      if Process.alive?(pid), do: enviar_notificacion(pid, mensaje)
    end

    nuevo_historial = actualizar_historial_en_mapa(state.historial, jugador_id, mensaje, now)
    persistir_historial(nuevo_historial)
    {:noreply, %{state | historial: nuevo_historial}}
  end

  def handle_call({:obtener_historial, jugador_id}, _from, state) do
    historial = Map.get(state.historial, jugador_id, [])
    {:reply, historial, state}
  end

  # Helpers
  defp enviar_notificacion(pid, mensaje) do
    send(pid, {:notificacion, mensaje})
  end

  defp actualizar_historial_en_mapa(historial, jugador_id, mensaje, fecha) do
    registro = %{fecha: fecha, mensaje: mensaje}

    Map.update(historial, jugador_id, [registro], fn lista ->
      [registro | lista]
    end)
  end

  defp cargar_historial do
    case File.read(@archivo_historial) do
      {:ok, contenido} ->
        case Jason.decode(contenido) do
          {:ok, mapa} -> for {k, v} <- mapa, into: %{}, do: {k, v}
          _ -> %{}
        end

      _ -> %{}
    end
  end

  defp persistir_historial(historial) do
    File.mkdir_p!("priv")
    File.write!(@archivo_historial, Jason.encode!(historial, pretty: true))
  end

  defp ahora_colombia do
    case DateTime.now("America/Bogota") do
      {:ok, dt} -> dt
      _ -> DateTime.utc_now()
    end
  end
end
