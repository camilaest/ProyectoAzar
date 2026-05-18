defmodule Azar.Reportes do
  @moduledoc """
  Módulo encargado de generar reportes del sistema Azar S.A.

  Provee tres tipos de reporte:
    - Reporte de ventas por sorteo (total recaudado, billetes vendidos)
    - Reporte de premios entregados (quién ganó qué y cuánto)
    - Reporte general del sistema (sorteos realizados, dinero movido, jugadores activos)

  Todos los reportes se muestran en consola con tablas con bordes.

  - fecha: Mayo del 2026
  - Licencia: GNU GPL v3
  """

  alias Azar.{SorteoServer, Apuesta}

  @ancho 60

  # ===========================================================================
  # API Pública
  # ===========================================================================

  @doc """
  Muestra el reporte de ventas de un sorteo específico:
  total recaudado, cantidad de billetes vendidos y fracciones.
  """
  def reporte_ventas(sorteo_id) do
    case SorteoServer.consultar_sorteo(sorteo_id) do
      {:error, razon} ->
        IO.puts("\n❌ Error: #{razon}")

      {:ok, sorteo} ->
        apuestas_sorteo =
          Apuesta.cargar_apuestas()
          |> Enum.filter(fn a ->
            to_string(a.sorteo_id) == to_string(sorteo.id)
          end)

        billetes_vendidos =
          sorteo.billetes
          |> Map.values()
          |> Enum.filter(fn b ->
            fracs = Map.get(b, :fracciones_vendidas, Map.get(b, "fracciones_vendidas", 0))
            fracs > 0
          end)
          |> length()

        total_fracciones =
          apuestas_sorteo
          |> Enum.filter(fn a -> a.estado == :activa end)
          |> Enum.reduce(0, fn a, acc -> acc + a.fracciones end)

        total_recaudado =
          apuestas_sorteo
          |> Enum.filter(fn a -> a.estado == :activa end)
          |> Enum.reduce(0, fn a, acc -> acc + a.monto end)

        imprimir_borde_top()
        imprimir_titulo("REPORTE DE VENTAS")
        imprimir_separador()
        imprimir_fila("Sorteo", sorteo.nombre)
        imprimir_fila("ID", to_string(sorteo.id))
        imprimir_fila("Estado", to_string(sorteo.estado))
        imprimir_fila("Precio por billete", "$#{sorteo.precio_billete}")
        imprimir_fila("Total billetes", to_string(sorteo.cantidad_billetes))
        imprimir_fila("Billetes vendidos", to_string(billetes_vendidos))
        imprimir_fila("Billetes disponibles", to_string(sorteo.cantidad_billetes - billetes_vendidos))
        imprimir_fila("Fracciones vendidas", to_string(total_fracciones))
        imprimir_fila("Compras registradas", to_string(length(apuestas_sorteo)))
        imprimir_separador()
        imprimir_fila("TOTAL RECAUDADO", "$#{total_recaudado}")
        imprimir_borde_bot()
    end
  end

  @doc """
  Muestra el reporte de premios entregados en un sorteo:
  quién ganó, qué billete, qué premio y cuánto vale.
  """
  def reporte_premios(sorteo_id) do
    case SorteoServer.consultar_sorteo(sorteo_id) do
      {:error, razon} ->
        IO.puts("\n❌ Error: #{razon}")

      {:ok, sorteo} ->
        imprimir_borde_top()
        imprimir_titulo("REPORTE DE PREMIOS ENTREGADOS")
        imprimir_separador()
        imprimir_fila("Sorteo", sorteo.nombre)
        imprimir_fila("ID", to_string(sorteo.id))
        imprimir_fila("Estado", to_string(sorteo.estado))
        imprimir_separador()

        if sorteo.ganadores == [] do
          imprimir_centro("(Sin ganadores — sorteo no finalizado)")
        else
          apuestas_sorteo =
            Apuesta.cargar_apuestas()
            |> Enum.filter(fn a ->
              to_string(a.sorteo_id) == to_string(sorteo.id) and a.estado == :activa
            end)

          Enum.each(sorteo.ganadores, fn ganador ->
            numero = Map.get(ganador, :numero_ganador, Map.get(ganador, "numero_ganador", "?"))
            premio_nombre = Map.get(ganador, :premio, Map.get(ganador, "premio", "?"))
            valor = Map.get(ganador, :valor, Map.get(ganador, "valor", 0))

            propietarios =
              apuestas_sorteo
              |> Enum.filter(fn a ->
                to_string(a.numero_billete) == to_string(numero)
              end)

            imprimir_fila("🏆 Premio", premio_nombre)
            imprimir_fila("   Valor", "$#{valor}")
            imprimir_fila("   Billete ganador", to_string(numero))

            if propietarios == [] do
              imprimir_fila("   Propietario", "(billete no vendido)")
            else
              Enum.each(propietarios, fn a ->
                imprimir_fila("   Jugador ID", a.jugador_id)
                imprimir_fila("   Fracciones", "#{a.fracciones} de #{sorteo.fracciones_totales}")
              end)
            end

            imprimir_separador()
          end)
        end

        imprimir_borde_bot()
    end
  end

  @doc """
  Muestra el reporte general del sistema:
  sorteos realizados, dinero total movido y jugadores activos.
  """
  def reporte_general do
    todos_sorteos = SorteoServer.listar_sorteos()
    todas_apuestas = Apuesta.cargar_apuestas()

    total_sorteos = length(todos_sorteos)

    sorteos_realizados =
      todos_sorteos |> Enum.count(fn s -> s.estado == :realizado end)

    sorteos_pendientes =
      todos_sorteos |> Enum.count(fn s -> s.estado == :pendiente end)

    apuestas_activas =
      todas_apuestas |> Enum.filter(fn a -> a.estado == :activa end)

    dinero_total =
      apuestas_activas |> Enum.reduce(0, fn a, acc -> acc + a.monto end)

    jugadores_activos =
      apuestas_activas
      |> Enum.map(fn a -> a.jugador_id end)
      |> Enum.uniq()
      |> length()

    total_premios =
      todos_sorteos
      |> Enum.flat_map(fn s -> s.ganadores end)
      |> Enum.reduce(0, fn g, acc ->
        acc + Map.get(g, :valor, Map.get(g, "valor", 0))
      end)

    imprimir_borde_top()
    imprimir_titulo("REPORTE GENERAL DEL SISTEMA")
    imprimir_separador()
    imprimir_titulo("Sorteos")
    imprimir_fila("Total de sorteos", to_string(total_sorteos))
    imprimir_fila("Sorteos realizados", to_string(sorteos_realizados))
    imprimir_fila("Sorteos pendientes", to_string(sorteos_pendientes))
    imprimir_separador()
    imprimir_titulo("Finanzas")
    imprimir_fila("Dinero total recaudado", "$#{dinero_total}")
    imprimir_fila("Total en premios asignados", "$#{total_premios}")
    imprimir_fila("Total apuestas activas", to_string(length(apuestas_activas)))
    imprimir_separador()
    imprimir_titulo("Jugadores")
    imprimir_fila("Jugadores con apuestas activas", to_string(jugadores_activos))
    imprimir_separador()

    if todos_sorteos != [] do
      imprimir_titulo("Detalle por sorteo")
      Enum.each(todos_sorteos, fn s ->
        ingresos =
          apuestas_activas
          |> Enum.filter(fn a -> to_string(a.sorteo_id) == to_string(s.id) end)
          |> Enum.reduce(0, fn a, acc -> acc + a.monto end)

        estado_str = case s.estado do
          :pendiente -> "Pendiente"
          :realizado -> "Realizado"
          :cancelado -> "Cancelado"
          otro -> to_string(otro)
        end

        imprimir_fila("#{s.nombre} (#{s.id})", "$#{ingresos} | #{estado_str}")
      end)
    end

    imprimir_borde_bot()
  end

  # ===========================================================================
  # Helpers privados de formato
  # ===========================================================================

  defp imprimir_borde_top do
    IO.puts("\n╔" <> String.duplicate("═", @ancho) <> "╗")
  end

  defp imprimir_borde_bot do
    IO.puts("╚" <> String.duplicate("═", @ancho) <> "╝\n")
  end

  defp imprimir_separador do
    IO.puts("╠" <> String.duplicate("═", @ancho) <> "╣")
  end

  defp imprimir_titulo(texto) do
    padding = div(@ancho - String.length(texto), 2)
    linea = String.duplicate(" ", padding) <> texto
    linea_ajustada = String.pad_trailing(linea, @ancho)
    IO.puts("║" <> linea_ajustada <> "║")
  end

  defp imprimir_centro(texto) do
    padding = div(@ancho - String.length(texto), 2)
    linea = String.duplicate(" ", padding) <> texto
    linea_ajustada = String.pad_trailing(linea, @ancho)
    IO.puts("║" <> linea_ajustada <> "║")
  end

  defp imprimir_fila(etiqueta, valor) do
    contenido = " #{etiqueta}: #{valor}"
    contenido_ajustado = String.pad_trailing(contenido, @ancho)
    IO.puts("║" <> contenido_ajustado <> "║")
  end
end
