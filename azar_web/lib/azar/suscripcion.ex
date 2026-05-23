defmodule Azar.Suscripcion do
  @moduledoc """
  Módulo auxiliar para gestionar suscripciones de jugadores a notificaciones.
  """

  alias Azar.Notificador

  @doc "Suscribe un jugador automáticamente (se llama al registrarse)."
  def suscribir_jugador(jugador_id) do
    Notificador.suscribir(jugador_id)
    {:ok, "Jugador #{jugador_id} suscrito a notificaciones"}
  end

  @doc "Desuscribe un jugador de las notificaciones."
  def desuscribir_jugador(jugador_id) do
    Notificador.desuscribir(jugador_id)
    {:ok, "Jugador #{jugador_id} desuscrito de notificaciones"}
  end

  @doc "Verifica si un jugador está suscrito."
  def esta_suscrito?(jugador_id) do
    Notificador.suscrito?(jugador_id)
  end

  @doc "Alterna la suscripción de un jugador."
  def alternar_suscripcion(jugador_id) do
    if esta_suscrito?(jugador_id) do
      desuscribir_jugador(jugador_id)
    else
      suscribir_jugador(jugador_id)
    end
  end
end
