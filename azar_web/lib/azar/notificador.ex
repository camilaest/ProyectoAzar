defmodule Azar.Notificador do
  @moduledoc """
  GenServer para el sistema de notificaciones en tiempo real de Azar S.A.
  Mantiene registro de jugadores suscritos y envía notificaciones de eventos.
  """
  use GenServer

  alias Azar.Logger

  @archivo_notificaciones "notificaciones.json"

  # ════════════════════════════════════════════
  # API Pública
  # ════════════════════════════════════════════

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Suscribe un jugador a las notificaciones."
  def suscribir(jugador_id) do
    GenServer.cast(__MODULE__, {:suscribir, jugador_id})
  end

  @doc "Desuscribe un jugador de las notificaciones."
  def desuscribir(jugador_id) do
    GenServer.cast(__MODULE__, {:desuscribir, jugador_id})
  end

  @doc "Notifica a todos los suscritos sobre un nuevo sorteo."
  def notificar_nuevo_sorteo(sorteo) do
    GenServer.cast(__MODULE__, {:notificar_sorteo, sorteo})
  end

  @doc "Notifica a todos los suscritos sobre el cierre de un sorteo."
  def notificar_cierre_sorteo(sorteo) do
    GenServer.cast(__MODULE__, {:notificar_cierre, sorteo})
  end

  @doc "Notifica a un jugador que ganó un premio."
  def notificar_premio(jugador_id, premio, sorteo_nombre) do
    GenServer.cast(__MODULE__, {:notificar_premio, jugador_id, premio, sorteo_nombre})
  end

  @doc "Obtiene las notificaciones de un jugador."
  def obtener_notificaciones(jugador_id) do
    GenServer.call(__MODULE__, {:obtener, jugador_id})
  end

  @doc "Verifica si un jugador está suscrito."
  def suscrito?(jugador_id) do
    GenServer.call(__MODULE__, {:suscrito, jugador_id})
  end

  # ════════════════════════════════════════════
  # Callbacks GenServer
  # ════════════════════════════════════════════

  @impl true
  def init(_) do
    estado = %{
      suscritos: MapSet.new(),
      notificaciones: cargar_notificaciones()
    }

    {:ok, estado}
  end

  @impl true
  def handle_cast({:suscribir, jugador_id}, estado) do
    nuevos_suscritos = MapSet.put(estado.suscritos, jugador_id)
    {:noreply, %{estado | suscritos: nuevos_suscritos}}
  end

  @impl true
  def handle_cast({:desuscribir, jugador_id}, estado) do
    nuevos_suscritos = MapSet.delete(estado.suscritos, jugador_id)
    {:noreply, %{estado | suscritos: nuevos_suscritos}}
  end

  @impl true
  def handle_cast({:notificar_sorteo, sorteo}, estado) do
    mensaje = "🎰 ¡Nuevo sorteo disponible! '#{sorteo.nombre}' - Fecha: #{sorteo.fecha} - Precio billete: $#{sorteo.precio_billete}"

    nuevas_notificaciones =
      Enum.reduce(estado.suscritos, estado.notificaciones, fn jugador_id, acc ->
        notif = crear_notificacion(jugador_id, :nuevo_sorteo, mensaje)
        agregar_notificacion(acc, jugador_id, notif)
      end)

    guardar_notificaciones(nuevas_notificaciones)
    Logger.registrar("Notificación", "Nuevo sorteo '#{sorteo.nombre}' notificado a #{MapSet.size(estado.suscritos)} jugadores")

    {:noreply, %{estado | notificaciones: nuevas_notificaciones}}
  end

  @impl true
  def handle_cast({:notificar_cierre, sorteo}, estado) do
    ganadores_texto =
      sorteo.ganadores
      |> Enum.map(fn g ->
        premio = Map.get(g, "premio") || Map.get(g, :premio)
        numero = Map.get(g, "numero_ganador") || Map.get(g, :numero_ganador)
        "#{premio}: ##{numero}"
      end)
      |> Enum.join(", ")

    mensaje = "🏆 Sorteo '#{sorteo.nombre}' cerrado. Ganadores: #{ganadores_texto}"

    nuevas_notificaciones =
      Enum.reduce(estado.suscritos, estado.notificaciones, fn jugador_id, acc ->
        notif = crear_notificacion(jugador_id, :cierre_sorteo, mensaje)
        agregar_notificacion(acc, jugador_id, notif)
      end)

    guardar_notificaciones(nuevas_notificaciones)
    {:noreply, %{estado | notificaciones: nuevas_notificaciones}}
  end

  @impl true
  def handle_cast({:notificar_premio, jugador_id, premio, sorteo_nombre}, estado) do
    mensaje = "🎉 ¡FELICIDADES! Ganaste el premio '#{premio}' en el sorteo '#{sorteo_nombre}'"

    notif = crear_notificacion(jugador_id, :premio_ganado, mensaje)

    nuevas_notificaciones =
      agregar_notificacion(estado.notificaciones, jugador_id, notif)

    guardar_notificaciones(nuevas_notificaciones)
    Logger.registrar("Notificación premio", "Jugador #{jugador_id} notificado de premio en '#{sorteo_nombre}'")

    {:noreply, %{estado | notificaciones: nuevas_notificaciones}}
  end

  @impl true
  def handle_call({:obtener, jugador_id}, _from, estado) do
    notifs = Map.get(estado.notificaciones, jugador_id, [])
    {:reply, notifs, estado}
  end

  @impl true
  def handle_call({:suscrito, jugador_id}, _from, estado) do
    {:reply, MapSet.member?(estado.suscritos, jugador_id), estado}
  end

  # ════════════════════════════════════════════
  # Helpers privados
  # ════════════════════════════════════════════

  defp crear_notificacion(jugador_id, tipo, mensaje) do
    %{
      "jugador_id" => jugador_id,
      "tipo" => to_string(tipo),
      "mensaje" => mensaje,
      "fecha" => DateTime.utc_now() |> DateTime.to_string(),
      "leida" => false
    }
  end

  defp agregar_notificacion(notificaciones, jugador_id, notif) do
    existentes = Map.get(notificaciones, jugador_id, [])
    Map.put(notificaciones, jugador_id, existentes ++ [notif])
  end

  defp guardar_notificaciones(notificaciones) do
    Jason.encode!(notificaciones, pretty: true)
    |> (&File.write!(@archivo_notificaciones, &1)).()
  end

  defp cargar_notificaciones do
    case File.read(@archivo_notificaciones) do
      {:ok, contenido} -> Jason.decode!(contenido)
      {:error, :enoent} -> %{}
    end
  end
end
