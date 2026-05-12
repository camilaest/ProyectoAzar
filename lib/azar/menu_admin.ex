defmodule Azar.MenuAdmin do

  def menu_admin do
    IO.puts("""

    ==================================
            MENÚ ADMINISTRADOR
    ==================================

    1. Crear nuevo sorteo
    2. Listar sorteos
    3. Finalizar sorteo
    4. Volver al menú principal

    ==================================

    """)

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do
      "1" ->
        crear_sorteo()
        pausa()
        menu_admin()

      "2" ->
        listar_sorteos()
        pausa()
        menu_admin()

      "3" ->
        finalizar_sorteo()
        pausa()
        menu_admin()

      "4" ->
        Estructura.menu_principal()

      _ ->
        IO.puts("\nOpción inválida.")
        pausa()
        menu_admin()
    end
  end

  # =========================
  # CREAR SORTEO
  # =========================

  def crear_sorteo do
    IO.puts("\n===== CREAR SORTEO =====\n")

    nombre =
      IO.gets("Ingrese el nombre del sorteo: ")
      |> String.trim()

    precio =
      IO.gets("Ingrese el precio del billete: ")
      |> String.trim()
      |> String.to_integer()

    premios =
      IO.gets("Ingrese los premios: ")
      |> String.trim()

    resultado =
      Azar.SorteoServer.crear_sorteo(%{
        nombre: nombre,
        precio_billete: precio,
        premios: premios
      })

    IO.puts("\nResultado:")
    IO.inspect(resultado)
  end

  # =========================
  # LISTAR SORTEOS
  # =========================

  def listar_sorteos do
    IO.puts("\n===== LISTA DE SORTEOS =====\n")

    sorteos = Azar.SorteoServer.listar_sorteos()

    IO.inspect(sorteos)
  end

  # =========================
  # FINALIZAR SORTEO
  # =========================

  def finalizar_sorteo do
    IO.puts("\n===== FINALIZAR SORTEO =====\n")

    id =
      IO.gets("Ingrese el ID del sorteo: ")
      |> String.trim()

    resultado =
      Azar.SorteoServer.finalizar_sorteo(id)

    IO.puts("\nResultado:")
    IO.inspect(resultado)
  end

  # =========================
  # PAUSA
  # =========================

  def pausa do
    IO.gets("\nPresione ENTER para continuar...")
  end

end
