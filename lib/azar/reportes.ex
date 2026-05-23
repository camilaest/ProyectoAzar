defmodule Azar.Reportes do
  @moduledoc """
  Módulo de generación de reportes para Azar S.A.
  Genera reportes de ventas, premios y estado general del sistema.
  """

  alias Azar.SorteoServer
  alias Azar.Apuesta
  alias Azar.Jugador
  alias Azar.Logger

  # ════════════════════════════════════════════
  # Reporte de Ventas por Sorteo
  # ════════════════════════════════════════════

  @doc "Genera un reporte de ventas detallado para un sorteo específico."
  def reporte_ventas(sorteo_id) do
    case SorteoServer.consultar_sorteo(sorteo_id) do
      {:ok, sorteo} ->
        apuestas = Apuesta.apuestas_por_sorteo(sorteo_id)
        total_apuestas = length(apuestas)
        total_recaudado = sorteo.ingresos_totales

        # Contar billetes vendidos (con al menos una fracción vendida)
        billetes_vendidos =
          sorteo.billetes
          |> Map.values()
          |> Enum.count(fn b ->
            vendidas = Map.get(b, :fracciones_vendidas) || Map.get(b, "fracciones_vendidas") || 0
            vendidas > 0
          end)

        reporte = """

        ╔══════════════════════════════════════════════════╗
        ║          REPORTE DE VENTAS - SORTEO              ║
        ╠══════════════════════════════════════════════════╣
        ║  Sorteo: #{String.pad_trailing(sorteo.nombre, 38)}║
        ║  ID: #{String.pad_trailing(to_string(sorteo.id), 42)}║
        ║  Estado: #{String.pad_trailing(to_string(sorteo.estado), 39)}║
        ║  Fecha: #{String.pad_trailing(to_string(sorteo.fecha), 39)}║
        ╠══════════════════════════════════════════════════╣
        ║  Total billetes:    #{String.pad_trailing(to_string(sorteo.cantidad_billetes), 27)}║
        ║  Billetes vendidos: #{String.pad_trailing(to_string(billetes_vendidos), 27)}║
        ║  Total apuestas:    #{String.pad_trailing(to_string(total_apuestas), 27)}║
        ║  Total recaudado:   $#{String.pad_trailing(to_string(total_recaudado), 26)}║
        ╚══════════════════════════════════════════════════╝
        """

        IO.puts(reporte)
        Logger.registrar("Reporte de ventas", "Generado para sorteo #{sorteo_id}")
        {:ok, reporte}

      {:error, msg} ->
        IO.puts("\n  ❌ #{msg}")
        {:error, msg}
    end
  end

  # ════════════════════════════════════════════
  # Reporte de Premios Entregados
  # ════════════════════════════════════════════

  @doc "Genera un reporte de premios entregados en sorteos realizados."
  def reporte_premios do
    sorteos = SorteoServer.listar_sorteos()

    realizados =
      Enum.filter(sorteos, fn s ->
        to_string(s.estado) == "realizado"
      end)

    encabezado = """

    ╔══════════════════════════════════════════════════════════════╗
    ║              REPORTE DE PREMIOS ENTREGADOS                  ║
    ╠══════════════════════════════════════════════════════════════╣
    """

    IO.write(encabezado)

    if Enum.empty?(realizados) do
      IO.puts("║  No hay sorteos realizados aún.                              ║")
    else
      Enum.each(realizados, fn sorteo ->
        IO.puts("║  Sorteo: #{sorteo.nombre} (ID: #{sorteo.id})")

        if is_list(sorteo.ganadores) and length(sorteo.ganadores) > 0 do
          Enum.each(sorteo.ganadores, fn ganador ->
            premio = Map.get(ganador, "premio") || Map.get(ganador, :premio) || "?"
            valor = Map.get(ganador, "valor") || Map.get(ganador, :valor) || 0
            numero = Map.get(ganador, "numero_ganador") || Map.get(ganador, :numero_ganador) || "?"

            IO.puts("║    🏆 #{premio}: $#{valor} → Billete ##{numero}")
          end)
        else
          IO.puts("║    Sin ganadores registrados.")
        end

        IO.puts("╠══════════════════════════════════════════════════════════════╣")
      end)
    end

    IO.puts("╚══════════════════════════════════════════════════════════════╝")
    Logger.registrar("Reporte de premios", "Generado con #{length(realizados)} sorteos realizados")
    :ok
  end

  # ════════════════════════════════════════════
  # Reporte General del Sistema
  # ════════════════════════════════════════════

  @doc "Genera un reporte general del estado del sistema."
  def reporte_general do
    sorteos = SorteoServer.listar_sorteos()
    jugadores = Jugador.cargar_jugadores()
    apuestas = Apuesta.listar_todas()

    total_sorteos = length(sorteos)
    pendientes = Enum.count(sorteos, fn s -> to_string(s.estado) == "pendiente" end)
    realizados = Enum.count(sorteos, fn s -> to_string(s.estado) == "realizado" end)
    cancelados = Enum.count(sorteos, fn s -> to_string(s.estado) == "cancelado" end)

    total_recaudado =
      sorteos
      |> Enum.map(fn s -> s.ingresos_totales || 0 end)
      |> Enum.sum()

    total_jugadores = length(jugadores)
    total_apuestas = length(apuestas)

    dinero_apuestas =
      apuestas
      |> Enum.map(fn a -> a.monto || 0 end)
      |> Enum.sum()

    reporte = """

    ╔══════════════════════════════════════════════════╗
    ║        REPORTE GENERAL DEL SISTEMA               ║
    ║              AZAR S.A.                            ║
    ╠══════════════════════════════════════════════════╣
    ║  SORTEOS                                         ║
    ║  ─────────────────────────────────────           ║
    ║  Total sorteos:       #{String.pad_trailing(to_string(total_sorteos), 25)}║
    ║  Pendientes:          #{String.pad_trailing(to_string(pendientes), 25)}║
    ║  Realizados:          #{String.pad_trailing(to_string(realizados), 25)}║
    ║  Cancelados:          #{String.pad_trailing(to_string(cancelados), 25)}║
    ╠══════════════════════════════════════════════════╣
    ║  JUGADORES                                       ║
    ║  ─────────────────────────────────────           ║
    ║  Total registrados:   #{String.pad_trailing(to_string(total_jugadores), 25)}║
    ╠══════════════════════════════════════════════════╣
    ║  FINANZAS                                        ║
    ║  ─────────────────────────────────────           ║
    ║  Total apuestas:      #{String.pad_trailing(to_string(total_apuestas), 25)}║
    ║  Dinero en apuestas:  $#{String.pad_trailing(to_string(dinero_apuestas), 24)}║
    ║  Total recaudado:     $#{String.pad_trailing(to_string(total_recaudado), 24)}║
    ╚══════════════════════════════════════════════════╝
    """

    IO.puts(reporte)
    Logger.registrar("Reporte general", "Generado exitosamente")
    :ok
  end
end
