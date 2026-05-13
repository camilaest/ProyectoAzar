defmodule AzarConcurrenciaTest do
  use ExUnit.Case, async: false

  alias Azar.{Apuesta, Billete, SorteoServer, Sorteo}

  # ============================================================
  # Tests de Billete
  # ============================================================

  describe "Azar.Billete" do
    test "nuevo/3 crea un billete con fracciones disponibles" do
      billete = Billete.nuevo("001", 1, 5)
      assert billete.numero == "001"
      assert billete.fracciones_disponibles == 5
      assert billete.fracciones_vendidas == 0
      assert billete.compradores == []
    end

    test "disponible?/1 retorna true si hay fracciones" do
      billete = Billete.nuevo("001", 1, 3)
      assert Billete.disponible?(billete) == true
    end

    test "disponible?/1 retorna false si no hay fracciones" do
      billete = %Billete{Billete.nuevo("001", 1, 0) | fracciones_disponibles: 0}
      assert Billete.disponible?(billete) == false
    end

    test "registrar_compra/4 reduce fracciones disponibles" do
      billete = Billete.nuevo("001", 1, 3)
      {:ok, actualizado} = Billete.registrar_compra(billete, "jugador1", 2, 1000)
      assert actualizado.fracciones_disponibles == 1
      assert actualizado.fracciones_vendidas == 2
      assert length(actualizado.compradores) == 1
    end

    test "registrar_compra/4 falla si no hay fracciones suficientes" do
      billete = Billete.nuevo("001", 1, 1)
      {:error, razon} = Billete.registrar_compra(billete, "jugador1", 2, 1000)
      assert razon =~ "Solo quedan"
    end

    test "registrar_compra/4 falla si el billete no tiene fracciones" do
      billete = %{Billete.nuevo("001", 1, 0) | fracciones_disponibles: 0}
      {:error, razon} = Billete.registrar_compra(billete, "jugador1", 1, 1000)
      assert razon =~ "no tiene fracciones"
    end
  end

  # ============================================================
  # Tests de Apuesta
  # ============================================================

  describe "Azar.Apuesta" do
    test "nueva/1 genera un struct con ID único" do
      apuesta = Apuesta.nueva(%{
        jugador_id: "123",
        sorteo_id: 1,
        numero_billete: "005",
        fracciones: 1,
        monto: 5000
      })
      assert apuesta.jugador_id == "123"
      assert apuesta.estado == :activa
      assert is_binary(apuesta.id)
    end

    test "dos apuestas tienen IDs distintos" do
      attrs = %{jugador_id: "123", sorteo_id: 1, numero_billete: "001", fracciones: 1, monto: 1000}
      a1 = Apuesta.nueva(attrs)
      a2 = Apuesta.nueva(attrs)
      assert a1.id != a2.id
    end
  end

  # ============================================================
  # Tests de Concurrencia — SorteoServer
  # ============================================================

  describe "Azar.SorteoServer — concurrencia" do
    setup do
      # Iniciamos un servidor fresco para cada test
      pid = case Process.whereis(SorteoServer) do
        nil ->
          {:ok, p} = SorteoServer.start_link([])
          p
        p -> p
      end

      {:ok, sorteo} = SorteoServer.crear_sorteo(%{
        nombre: "Sorteo Test",
        precio_billete: 3000,
        fracciones_totales: 3,
        cantidad_billetes: 1,
        premios: [%{nombre: "Premio Test", valor: 50_000}]
      })

      {:ok, sorteo: sorteo, pid: pid}
    end

    test "comprar_fraccion/4 registra una compra exitosa", %{sorteo: sorteo} do
      {:ok, apuesta} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador1", 1)
      assert apuesta.jugador_id == "jugador1"
      assert apuesta.estado == :activa
    end

    test "no se puede comprar más fracciones de las disponibles", %{sorteo: sorteo} do
      {:ok, _} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador1", 1)
      {:ok, _} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador2", 1)
      {:ok, _} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador3", 1)
      # La 4ta debe fallar
      {:error, razon} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador4", 1)
      assert razon =~ "fracciones"
    end

    test "sin sobreventa con múltiples procesos en paralelo", %{sorteo: sorteo} do
      # 10 jugadores intentan comprar 1 fracción al mismo tiempo
      # Solo 3 pueden tener éxito (fracciones_totales: 3)
      tareas =
        1..10
        |> Enum.map(fn n ->
          Task.async(fn ->
            SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador_#{n}", 1)
          end)
        end)

      resultados = Enum.map(tareas, &Task.await(&1, 5000))

      exitosos = Enum.count(resultados, fn
        {:ok, _} -> true
        _ -> false
      end)

      # Exactamente 3 deben tener éxito (fracciones_totales: 3)
      assert exitosos == 3
    end

    test "no se puede comprar en sorteo finalizado", %{sorteo: sorteo} do
      SorteoServer.finalizar_sorteo(sorteo.id)
      {:error, razon} = SorteoServer.comprar_fraccion(sorteo.id, "001", "jugador1", 1)
      assert razon =~ "no está disponible"
    end
  end
end
