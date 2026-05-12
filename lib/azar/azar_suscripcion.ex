# lib/azar/suscripcion.ex
defmodule Azar.Suscripcion do
  alias Azar.Notificador

  def registrar_jugador(attrs) do
    jugador_id = Map.fetch!(attrs, :id)
    pid = Map.get(attrs, :pid, self())
    suscribir_automaticamente(jugador_id, pid)
    {:ok, attrs}
  end

  def suscribir_automaticamente(jugador_id, pid \\ self()) do
    Notificador.suscribir(jugador_id, pid)
  end

  def desuscribir_jugador(jugador_id) do
    Notificador.desuscribir(jugador_id)
  end

  def notificaciones_pasadas(jugador_id) do
    Notificador.obtener_historial(jugador_id)
  end

  def guardar_notificacion(jugador_id, mensaje) do
    Notificador.notificar_ganador(jugador_id, mensaje)
  end
end
