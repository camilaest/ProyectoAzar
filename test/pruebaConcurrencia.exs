defmodule PruebaConcurrencia do
  @moduledoc """
  Script de prueba para verificar que el SorteoServer maneja correctamente
  múltiples apuestas simultáneas sin inconsistencias (sin sobreventa de fracciones).

  Sigue la estructura de Problema No. 17 (Task.async) del curso.

  Uso:
    mix run test/prueba_concurrencia.exs

  - fecha: Mayo del 2026
  """

  alias Azar.{SorteoServer, Sorteo}

  @cantidad_compradores 20      # Jugadores intentando comprar al mismo tiempo
  @fracciones_por_billete 3     # Fracciones disponibles en el billete de prueba
  @precio_billete 9000          # Precio del billete completo

  def main do
    IO.puts("=" |> String.duplicate(50))
    IO.puts("   PRUEBA DE CONCURRENCIA — AZAR S.A.")
    IO.puts("=" |> String.duplicate(50))

    # Iniciamos el servidor si no está corriendo
    asegurar_servidor()

    # Creamos un sorteo de prueba con 1 billete que tiene @fracciones_por_billete fracciones
    {:ok, sorteo} = SorteoServer.crear_sorteo(%{
      nombre: "Sorteo Prueba Concurrencia",
      precio_billete: @precio_billete,
      fracciones_totales: @fracciones_por_billete,
      cantidad_billetes: 1,
      premios: [%{nombre: "Premio Mayor", valor: 100_000}]
    })

    numero_billete = "001"
    sorteo_id = sorteo.id

    IO.puts("\nSorteo creado: ID=#{sorteo_id}")
    IO.puts("Billete '#{numero_billete}' tiene #{@fracciones_por_billete} fracciones disponibles")
    IO.puts("Lanzando #{@cantidad_compradores} compradores en paralelo...\n")

    tiempo_inicio = System.monotonic_time()

    # Lanzamos todos los compradores en paralelo usando Task.async
    # (igual que el Problema No. 17 del PDF)
    tareas =
      1..@cantidad_compradores
      |> Enum.map(fn n ->
        jugador_id = "jugador_#{String.pad_leading(to_string(n), 2, "0")}"
        Task.async(fn ->
          resultado = SorteoServer.comprar_fraccion(sorteo_id, numero_billete, jugador_id, 1)
          {jugador_id, resultado}
        end)
      end)

    # Esperamos a que todos terminen
    resultados = Enum.map(tareas, &Task.await(&1, 10_000))

    tiempo_final = System.monotonic_time()
    duracion = System.convert_time_unit(tiempo_final - tiempo_inicio, :native, :microsecond)

    # Analizamos resultados
    {exitosos, fallidos} = Enum.split_with(resultados, fn
      {_, {:ok, _}} -> true
      _ -> false
    end)

    IO.puts("─" |> String.duplicate(50))
    IO.puts("RESULTADOS:")
    IO.puts("─" |> String.duplicate(50))

    IO.puts("\n Compras exitosas (#{length(exitosos)}):")
    Enum.each(exitosos, fn {jugador, {:ok, apuesta}} ->
      IO.puts("   #{jugador} → Apuesta #{apuesta.id} | Fracción del billete #{apuesta.numero_billete}")
    end)

    IO.puts("\n Intentos fallidos (#{length(fallidos)}):")
    Enum.each(fallidos, fn {jugador, {:error, razon}} ->
      IO.puts("   #{jugador} → #{razon}")
    end)

    IO.puts("\n" <> "─" |> String.duplicate(50))
    IO.puts("VERIFICACIÓN:")
    IO.puts("─" |> String.duplicate(50))

    # Verificamos que no hubo sobreventa
    fracciones_vendidas = length(exitosos)
    sobreventa = fracciones_vendidas > @fracciones_por_billete

    if sobreventa do
      IO.puts("\n SOBREVENTA DETECTADA: se vendieron #{fracciones_vendidas} fracciones pero solo había #{@fracciones_por_billete}")
    else
      IO.puts("\n Sin sobreventa: #{fracciones_vendidas}/#{@fracciones_por_billete} fracciones vendidas correctamente")
    end

    IO.puts("  Tiempo total: #{duracion} microsegundos")
    IO.puts("\n" <> "=" |> String.duplicate(50))

    # Speedup vs secuencial (concepto del PDF)
    IO.puts("\nNOTA: En una versión secuencial, los #{@cantidad_compradores} procesos")
    IO.puts("se ejecutarían uno tras otro. Con Task.async corren en paralelo,")
    IO.puts("pero la serialización del GenServer garantiza atomicidad.")
  end

  defp asegurar_servidor do
    case Process.whereis(Azar.SorteoServer) do
      nil ->
        {:ok, _} = Azar.SorteoServer.start_link([])
        IO.puts("Servidor SorteoServer iniciado.")
      _pid ->
        IO.puts("Servidor SorteoServer ya estaba corriendo.")
    end
  end
end

PruebaConcurrencia.main()
