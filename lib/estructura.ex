defmodule Estructura do
  def main do
    jugadores =
      Azar.Jugador.ingresar("Registro de jugadores", :jugadores)

    jugadores
    |> Azar.Jugador.escribir_json("jugadores.json")

  end
  end
