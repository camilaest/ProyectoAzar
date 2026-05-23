defmodule Azar.Admin do
  @moduledoc """
  Menú de administrador de Azar S.A.
  """

  alias Azar.{SorteoServer, Reportes, Util}

  def menu do
    IO.puts("""

    ═══════════════════════════════════════
        MENU ADMINISTRADOR - AZAR S.A.
    ═══════════════════════════════════════
    1. Crear nuevo sorteo
    2. Listar sorteos
    3. Filtrar sorteos (por estado)
    4. Consultar estado de sorteo
    5. Cerrar sorteo (generar ganadores)
    6. Cancelar sorteo
    7. Generar reportes
    8. Volver al menu principal
    ═══════════════════════════════════════
    """)

    opcion = Util.ingresar("  Seleccione una opcion: ", :entero)

    case opcion do
      1 -> crear_sorteo()
      2 -> listar_sorteos()
      3 -> filtrar_sorteos()
      4 -> consultar_sorteo()
      5 -> cerrar_sorteo()
      6 -> cancelar_sorteo()
      7 -> menu_reportes()
      8 -> :volver
      _ ->
        IO.puts("\n  Opcion no valida.")
        menu()
    end
  end

  defp crear_sorteo do
    IO.puts("\n  === CREAR NUEVO SORTEO ===\n")
    nombre = Util.ingresar("  Nombre del sorteo: ", :texto)
    fecha = Util.ingresar("  Fecha (YYYY-MM-DD): ", :texto)
    precio = Util.ingresar("  Precio por billete: ", :entero)
    fracciones = Util.ingresar("  Fracciones por billete: ", :entero)
    cantidad = Util.ingresar("  Cantidad de billetes: ", :entero)

    IO.puts("\n  -- Definir premios --")
    premios = ingresar_premios([])

    attrs = %{
      nombre: nombre, fecha: fecha, precio_billete: precio,
      fracciones_totales: fracciones, cantidad_billetes: cantidad,
      premios: premios
    }

    case SorteoServer.crear_sorteo(attrs) do
      {:ok, sorteo} ->
        try do Azar.Notificador.notificar_nuevo_sorteo(sorteo) catch _, _ -> :ok end
        IO.puts("\n  Sorteo '#{sorteo.nombre}' creado! ID: #{sorteo.id}")
      {:error, msg} -> IO.puts("\n  Error: #{msg}")
    end
    menu()
  end

  defp ingresar_premios(lista) do
    n = length(lista) + 1
    IO.puts("  Premio ##{n}:")
    nombre = Util.ingresar("    Nombre: ", :texto)
    valor = Util.ingresar("    Valor: ", :entero)
    nueva = lista ++ [%{"nombre" => nombre, "valor" => valor}]
    if Util.ingresar("  Agregar otro? (si/no): ", :boolean), do: ingresar_premios(nueva), else: nueva
  end

  defp listar_sorteos do
    sorteos = SorteoServer.listar_sorteos()
    if Enum.empty?(sorteos) do
      IO.puts("\n  No hay sorteos registrados.\n")
    else
      IO.puts("\n  === LISTADO DE SORTEOS ===")
      Enum.each(sorteos, fn s ->
        IO.puts("  #{em(s.estado)} ID: #{s.id} | #{s.nombre} | #{s.fecha} | #{s.estado} | $#{s.precio_billete}")
      end)
    end
    menu()
  end

  defp filtrar_sorteos do
    IO.puts("\n  1. Pendiente  2. Realizado  3. Cancelado")
    estado = case Util.ingresar("  Filtro: ", :entero) do
      1 -> :pendiente; 2 -> :realizado; 3 -> :cancelado; _ -> nil
    end
    if estado do
      filtrados = SorteoServer.filtrar_sorteos({:estado, estado})
      if Enum.empty?(filtrados), do: IO.puts("  Sin resultados."),
        else: Enum.each(filtrados, fn s -> IO.puts("  #{em(s.estado)} #{s.id} | #{s.nombre} | #{s.fecha}") end)
    end
    menu()
  end

  defp consultar_sorteo do
    id = Util.ingresar("\n  ID del sorteo: ", :entero)
    case SorteoServer.consultar_sorteo(id) do
      {:ok, s} ->
        IO.puts("\n  === DETALLE SORTEO ===")
        IO.puts("  ID: #{s.id} | Nombre: #{s.nombre} | Fecha: #{s.fecha}")
        IO.puts("  Estado: #{s.estado} | Precio: $#{s.precio_billete} | Ingresos: $#{s.ingresos_totales}")
        IO.puts("  Billetes: #{s.cantidad_billetes} | Fracciones: #{s.fracciones_totales}")
        if is_list(s.premios), do: Enum.each(s.premios, fn p ->
          IO.puts("  Premio: #{Map.get(p,"nombre")||Map.get(p,:nombre)} - $#{Map.get(p,"valor")||Map.get(p,:valor)}")
        end)
        if to_string(s.estado) == "realizado" and is_list(s.ganadores) do
          IO.puts("  --- Ganadores ---")
          Enum.each(s.ganadores, fn g ->
            IO.puts("  #{Map.get(g,"premio")||Map.get(g,:premio)}: Billete ##{Map.get(g,"numero_ganador")||Map.get(g,:numero_ganador)}")
          end)
        end
      {:error, msg} -> IO.puts("  Error: #{msg}")
    end
    menu()
  end

  defp cerrar_sorteo do
    id = Util.ingresar("\n  ID del sorteo a cerrar: ", :entero)
    if Util.ingresar("  Confirmar? (si/no): ", :boolean) do
      case SorteoServer.cerrar_sorteo(id) do
        {:ok, s} ->
          try do Azar.Notificador.notificar_cierre_sorteo(s) catch _, _ -> :ok end
          IO.puts("  Sorteo cerrado! Ganadores:")
          Enum.each(s.ganadores, fn g ->
            IO.puts("  #{Map.get(g,"premio")||Map.get(g,:premio)} ($#{Map.get(g,"valor")||Map.get(g,:valor)}) -> ##{Map.get(g,"numero_ganador")||Map.get(g,:numero_ganador)}")
          end)
        {:error, msg} -> IO.puts("  Error: #{msg}")
      end
    end
    menu()
  end

  defp cancelar_sorteo do
    id = Util.ingresar("\n  ID del sorteo a cancelar: ", :entero)
    if Util.ingresar("  Confirmar? (si/no): ", :boolean) do
      case SorteoServer.cancelar_sorteo(id) do
        {:ok, s} -> IO.puts("  Sorteo '#{s.nombre}' cancelado.")
        {:error, msg} -> IO.puts("  Error: #{msg}")
      end
    end
    menu()
  end

  defp menu_reportes do
    IO.puts("\n  1. Ventas por sorteo  2. Premios  3. General  4. Volver")
    case Util.ingresar("  Opcion: ", :entero) do
      1 -> id = Util.ingresar("  ID sorteo: ", :entero); Reportes.reporte_ventas(id)
      2 -> Reportes.reporte_premios()
      3 -> Reportes.reporte_general()
      4 -> :ok
      _ -> IO.puts("  Opcion no valida.")
    end
    menu()
  end

  defp em(estado) do
    case to_string(estado) do
      "pendiente" -> "[P]"; "realizado" -> "[R]"; "cancelado" -> "[C]"; _ -> "[?]"
    end
  end
end
