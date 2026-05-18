defmodule Azar.MenuAdmin do
  @moduledoc """
  Menú interactivo para el administrador del sistema Azar S.A.
  Permite gestionar sorteos, ver reportes y conectarse como nodo remoto.
  """

  alias Azar.Reportes

  def menu_admin do
    IO.puts("""

    ==================================
            MENÚ ADMINISTRADOR
    ==================================

    1. Crear nuevo sorteo
    2. Listar sorteos
    3. Filtrar sorteos (por fecha/estado)
    4. Consultar estado de sorteo
    5. Cerrar sorteo (generar ganadores)
    6. Generar reportes
    7. Conectarse como cliente remoto
    8. Volver al menú principal

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
        filtrar_sorteos()
        pausa()
        menu_admin()

      "4" ->
        consultar_estado()
        pausa()
        menu_admin()

      "5" ->
        finalizar_sorteo()
        pausa()
        menu_admin()

      "6" ->
        menu_reportes()

      "7" ->
        conectar_nodo_remoto()
        pausa()
        menu_admin()

      "8" ->
        Estructura.menu_principal()

      _ ->
        IO.puts("\nOpción inválida.")
        pausa()
        menu_admin()
    end
  end

  # SUBMENÚ DE REPORTES

  def menu_reportes do
    IO.puts("""

    ==================================
            REPORTES DEL SISTEMA
    ==================================

    1. Reporte de ventas por sorteo
    2. Reporte de premios entregados
    3. Reporte general del sistema
    4. Volver al menú administrador

    ==================================

    """)

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do
      "1" ->
        reporte_ventas()
        pausa()
        menu_reportes()

      "2" ->
        reporte_premios()
        pausa()
        menu_reportes()

      "3" ->
        Reportes.reporte_general()
        pausa()
        menu_reportes()

      "4" ->
        menu_admin()

      _ ->
        IO.puts("\nOpción inválida.")
        pausa()
        menu_reportes()
    end
  end

  # CREAR SORTEO

  def crear_sorteo do
    IO.puts("\n===== CREAR SORTEO =====\n")

    nombre =
      IO.gets("Ingrese el nombre del sorteo: ")
      |> String.trim()

    precio =
  IO.gets("Ingrese el precio del billete: ")
  |> String.trim()
  |> Integer.parse()
  |> case do
    {n, _} -> n
    :error ->
      IO.puts("Valor inválido, se usará 0.")
      0
  end

    fracciones =
  IO.gets("Ingrese la cantidad de fracciones por billete: ")
  |> String.trim()
  |> Integer.parse()
  |> case do
    {n, _} -> n
    :error ->
      IO.puts("Valor inválido, se usará 1.")
      1
  end

    cantidad_billetes =
  IO.gets("Ingrese la cantidad de billetes: ")
  |> String.trim()
  |> Integer.parse()
  |> case do
    {n, _} -> n
    :error ->
      IO.puts("Valor inválido, se usará 0.")
      0
  end

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
        IO.puts("\n✅ Sorteo creado exitosamente!")
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
        IO.puts("\n❌ Error al crear sorteo: #{razon}")
    end
  end

  # LISTAR SORTEOS

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

  # FILTRAR SORTEOS

  defp filtrar_sorteos do
    IO.puts("\n===== FILTRAR SORTEOS =====\n")
    IO.puts("Filtrar por estado:")
    IO.puts("  1. Pendientes")
    IO.puts("  2. Realizados")
    IO.puts("  3. Todos")

    opcion = IO.gets("\nSeleccione: ") |> String.trim()

    sorteos =
      case opcion do
        "1" ->
          Azar.SorteoServer.listar_sorteos()
          |> Enum.filter(fn s -> s.estado == :pendiente end)

        "2" ->
          Azar.SorteoServer.listar_sorteos()
          |> Enum.filter(fn s -> s.estado == :realizado end)

        _ ->
          Azar.SorteoServer.listar_sorteos()
      end

    if sorteos == [] do
      IO.puts("\nNo hay sorteos con ese filtro.")
    else
      Enum.each(sorteos, fn s ->
        IO.puts("─────────────────────────────────────")
        IO.puts("ID     : #{s.id}")
        IO.puts("Nombre : #{s.nombre}")
        IO.puts("Estado : #{s.estado}")
        IO.puts("Precio : $#{s.precio_billete}")
      end)
      IO.puts("─────────────────────────────────────")
    end
  end

  # CONSULTAR ESTADO DE SORTEO

  defp consultar_estado do
    IO.puts("\n===== CONSULTAR ESTADO DE SORTEO =====\n")

    sorteos = Azar.SorteoServer.listar_sorteos()

    if sorteos == [] do
      IO.puts("No hay sorteos registrados.")
    else
      IO.puts("Sorteos disponibles:")
      Enum.each(sorteos, fn s ->
        IO.puts("  ID: #{s.id} | #{s.nombre} | Estado: #{s.estado}")
      end)

      id_str = IO.gets("\nIngrese el ID del sorteo: ") |> String.trim()
      id = case Integer.parse(id_str) do
        {n, _} -> n
        :error -> id_str
      end

      case Azar.SorteoServer.consultar_sorteo(id) do
        {:ok, sorteo} ->
          IO.puts("\n───────────────────────────────────")
          IO.puts("ID         : #{sorteo.id}")
          IO.puts("Nombre     : #{sorteo.nombre}")
          IO.puts("Estado     : #{sorteo.estado}")
          IO.puts("Precio     : $#{sorteo.precio_billete}")
          IO.puts("Billetes   : #{sorteo.cantidad_billetes}")
          IO.puts("Fracciones : #{sorteo.fracciones_totales} por billete")

          premios_str = Enum.map_join(sorteo.premios, ", ", fn p ->
            Map.get(p, :nombre, Map.get(p, "nombre", "?"))
          end)
          IO.puts("Premios    : #{premios_str}")

          if sorteo.ganadores != [] do
            IO.puts("Ganadores  :")
            Enum.each(sorteo.ganadores, fn g ->
              numero = Map.get(g, :numero_ganador, Map.get(g, "numero_ganador", "?"))
              premio = Map.get(g, :premio, Map.get(g, "premio", "?"))
              valor  = Map.get(g, :valor,  Map.get(g, "valor",  0))
              IO.puts("  🏆 Billete #{numero} → #{premio} ($#{valor})")
            end)
          end
          IO.puts("───────────────────────────────────")

        {:error, razon} ->
          IO.puts("\n❌ Error: #{razon}")
      end
    end
  end

  # FINALIZAR SORTEO

  def finalizar_sorteo do
    IO.puts("\n===== FINALIZAR SORTEO =====\n")

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
  case IO.gets("\nIngrese el ID del sorteo a finalizar: ") |> String.trim() |> Integer.parse() do
    {n, _} -> n
    :error -> nil
  end

      if id == nil do
  IO.puts("\n❌ ID inválido.")
else
  resultado = Azar.SorteoServer.finalizar_sorteo(id)

  case resultado do
    {:ok, sorteo} ->
      IO.puts("\n✅ ¡Sorteo '#{sorteo.nombre}' finalizado!")
      IO.puts("\nGanadores:")
      Enum.each(sorteo.ganadores, fn g ->
        numero = Map.get(g, :numero_ganador, Map.get(g, "numero_ganador", "?"))
        premio = Map.get(g, :premio, Map.get(g, "premio", "?"))
        valor  = Map.get(g, :valor,  Map.get(g, "valor",  0))
        IO.puts("   Billete #{numero} → #{premio} ($#{valor})")
      end)

    {:error, razon} ->
      IO.puts("\n❌ Error: #{razon}")
  end
end

      case resultado do
        {:ok, sorteo} ->
          IO.puts("\n✅ ¡Sorteo '#{sorteo.nombre}' finalizado!")
          IO.puts("\nGanadores:")
          Enum.each(sorteo.ganadores, fn g ->
            numero = Map.get(g, :numero_ganador, Map.get(g, "numero_ganador", "?"))
            premio = Map.get(g, :premio, Map.get(g, "premio", "?"))
            valor  = Map.get(g, :valor,  Map.get(g, "valor",  0))
            IO.puts("   Billete #{numero} → #{premio} ($#{valor})")
          end)

        {:error, razon} ->
          IO.puts("\n❌ Error: #{razon}")
      end
    end
  end

  # REPORTES (privados — se llaman desde menu_reportes)

  defp reporte_ventas do
    IO.puts("\n===== REPORTE DE VENTAS =====\n")
    sorteos = Azar.SorteoServer.listar_sorteos()

    if sorteos == [] do
      IO.puts("No hay sorteos registrados.")
    else
      IO.puts("Sorteos disponibles:")
      Enum.each(sorteos, fn s ->
        IO.puts("  ID: #{s.id} | #{s.nombre} | Estado: #{s.estado}")
      end)

      id_str = IO.gets("\nIngrese el ID del sorteo: ") |> String.trim()
      id = case Integer.parse(id_str) do
        {n, _} -> n
        :error -> id_str
      end

      Reportes.reporte_ventas(id)
    end
  end

  defp reporte_premios do
    IO.puts("\n===== REPORTE DE PREMIOS =====\n")
    sorteos = Azar.SorteoServer.listar_sorteos()

    if sorteos == [] do
      IO.puts("No hay sorteos registrados.")
    else
      IO.puts("Sorteos disponibles:")
      Enum.each(sorteos, fn s ->
        IO.puts("  ID: #{s.id} | #{s.nombre} | Estado: #{s.estado}")
      end)

      id_str = IO.gets("\nIngrese el ID del sorteo: ") |> String.trim()
      id = case Integer.parse(id_str) do
        {n, _} -> n
        :error -> id_str
      end

      Reportes.reporte_premios(id)
    end
  end

  # CONECTAR NODO REMOTO (recuperado en opción 7)

  defp conectar_nodo_remoto do
    IO.puts("\n===== CONECTAR NODO REMOTO =====\n")
    IO.puts("Nodo actual: #{Node.self()}")

    nodo_str =
      IO.gets("Ingrese el nombre del nodo remoto (ej: azar@192.168.1.5): ")
      |> String.trim()

    if nodo_str == "" do
      IO.puts("\nOperación cancelada.")
    else
      nodo = String.to_atom(nodo_str)
      IO.puts("Intentando conectar a #{nodo}...")

      case Node.connect(nodo) do
        true ->
          IO.puts("\n✅ Conectado exitosamente a #{nodo}")
          IO.puts("Nodos conectados: #{inspect(Node.list())}")

        false ->
          IO.puts("\n❌ No se pudo conectar a #{nodo}")
          IO.puts("Verifique que:")
          IO.puts("  - El nodo remoto esté en línea")
          IO.puts("  - Usen el mismo cookie Erlang (--cookie)")
          IO.puts("  - La red permita la conexión")

        :ignored ->
          IO.puts("\n⚠️  Conexión ignorada (ya conectado o es el nodo local)")
      end
    end
  end

  # PAUSA

  def pausa do
    IO.gets("\nPresione ENTER para continuar...")
  end
end
