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

    fracciones =
      IO.gets("Ingrese la cantidad de fracciones por billete: ")
      |> String.trim()
      |> String.to_integer()

    cantidad_billetes =
      IO.gets("Ingrese la cantidad de billetes: ")
      |> String.trim()
      |> String.to_integer()

    premios =
      IO.gets("Ingrese los premios (separados por coma): ")
      |> String.trim()

    resultado =
      Azar.SorteoServer.crear_sorteo(%{
        nombre: nombre,
        precio_billete: precio,
        fracciones_totales: fracciones,
        cantidad_billetes: cantidad_billetes,
        premios: premios
      })

    case resultado do
      {:ok, sorteo} ->
        IO.puts("\n Sorteo creado exitosamente!")
        IO.puts("   ID        : #{sorteo.id}")
        IO.puts("   Nombre    : #{sorteo.nombre}")
        IO.puts("   Precio    : $#{sorteo.precio_billete}")
        IO.puts("   Billetes  : #{sorteo.cantidad_billetes}")
        IO.puts("   Fracciones: #{sorteo.fracciones_totales} por billete")
        premios_str = Enum.map_join(sorteo.premios, ", ", fn p ->
          Map.get(p, :nombre, Map.get(p, "nombre", "?"))
        end)
        IO.puts("   Premios   : #{premios_str}")

      {:error, razon} ->
        IO.puts("\n Error al crear sorteo: #{razon}")
    end
  end

  # =========================
  # LISTAR SORTEOS
  # =========================

  def listar_sorteos do
    IO.puts("\n===== LISTA DE SORTEOS =====\n")

    sorteos = Azar.SorteoServer.listar_sorteos()

    if sorteos == [] do
      IO.puts("No hay sorteos registrados.")
    else
      Enum.each(sorteos, fn s ->
        IO.puts("─────────────────────────────────────")
        IO.puts("ID        : #{s.id}")
        IO.puts("Nombre    : #{s.nombre}")
        IO.puts("Precio    : $#{s.precio_billete}")
        IO.puts("Estado    : #{s.estado}")
        IO.puts("Billetes  : #{s.cantidad_billetes} | Fracciones: #{s.fracciones_totales} por billete")

        premios_str = Enum.map_join(s.premios, ", ", fn p ->
          Map.get(p, :nombre, Map.get(p, "nombre", "?"))
        end)
        IO.puts("Premios   : #{premios_str}")

        if s.ganadores != [] do
          IO.puts("Ganadores :")
          Enum.each(s.ganadores, fn g ->
            numero = Map.get(g, :numero_ganador, Map.get(g, "numero_ganador", "?"))
            premio = Map.get(g, :premio, Map.get(g, "premio", "?"))
            IO.puts("  🏆 Billete #{numero} → #{premio}")
          end)
        end
      end)
      IO.puts("─────────────────────────────────────")
    end
  end

  # =========================
  # FINALIZAR SORTEO
  # =========================

  def finalizar_sorteo do
    IO.puts("\n===== FINALIZAR SORTEO =====\n")

    # Mostrar sorteos pendientes para facilitar la selección
    pendientes =
      Azar.SorteoServer.listar_sorteos()
      |> Enum.filter(fn s -> s.estado == :pendiente end)

    if pendientes == [] do
      IO.puts("No hay sorteos pendientes para finalizar.")
    else
      IO.puts("Sorteos pendientes:")
      Enum.each(pendientes, fn s ->
        IO.puts("  ID: #{s.id} | #{s.nombre} | $#{s.precio_billete}")
      end)

      id =
        IO.gets("\nIngrese el ID del sorteo a finalizar: ")
        |> String.trim()

      resultado = Azar.SorteoServer.finalizar_sorteo(id)

      case resultado do
        {:ok, sorteo} ->
          IO.puts("\n ¡Sorteo '#{sorteo.nombre}' finalizado!")
          IO.puts("\nGanadores:")
          Enum.each(sorteo.ganadores, fn g ->
            numero = Map.get(g, :numero_ganador, Map.get(g, "numero_ganador", "?"))
            premio = Map.get(g, :premio, Map.get(g, "premio", "?"))
            valor = Map.get(g, :valor, Map.get(g, "valor", 0))
            IO.puts("   Billete #{numero} → #{premio} ($#{valor})")
          end)

        {:error, razon} ->
          IO.puts("\n Error: #{razon}")
      end
    end
  end

  # =========================
  # PAUSA
  # =========================

  def pausa do
    IO.gets("\nPresione ENTER para continuar...")
  end

end
