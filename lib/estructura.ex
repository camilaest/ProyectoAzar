defmodule Estructura do
  def menu_principal do
    IO.puts("""

    ══════════════════════════════════
          AZAR S.A. - Sorteos
    ══════════════════════════════════

    1. Ingresar como Administrador
    2. Ingresar como Jugador
    3. Salir

    ══════════════════════════════════
    """)

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do
      "1" ->
        Azar.MenuAdmin.menu_admin()

      "2" ->
        Azar.MenuJugador.menu_jugador()

      "3" ->
        IO.puts("\n¡Hasta luego!")

      _ ->
        IO.puts("\nOpción inválida. Intente de nuevo.")
        menu_principal()
    end
  end
end
