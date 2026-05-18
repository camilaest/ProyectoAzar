defmodule SorteoTest do
  use ExUnit.Case, async: false

  alias Azar.Sorteo

  describe "Azar.Sorteo" do
    test "nueva_instancia/1 crea un sorteo con los campos correctos" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Rifa Test",
        precio_billete: 10_000,
        fracciones_totales: 2,
        cantidad_billetes: 5,
        premios: [%{nombre: "Primer Premio", valor: 100_000}]
      })

      assert sorteo.nombre == "Rifa Test"
      assert sorteo.precio_billete == 10_000
      assert sorteo.fracciones_totales == 2
      assert sorteo.cantidad_billetes == 5
      assert sorteo.estado == :pendiente
      assert sorteo.ganadores == []
      assert sorteo.ingresos_totales == 0
      assert is_integer(sorteo.id)
    end

    test "nueva_instancia/1 genera los billetes correctamente" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Rifa Billetes",
        precio_billete: 5000,
        fracciones_totales: 2,
        cantidad_billetes: 10,
        premios: []
      })

      assert map_size(sorteo.billetes) == 10
    end

    test "nueva_instancia/1 genera IDs distintos en cada llamado" do
      s1 = Sorteo.nueva_instancia(%{nombre: "A", precio_billete: 1000, fracciones_totales: 1, cantidad_billetes: 1, premios: []})
      s2 = Sorteo.nueva_instancia(%{nombre: "B", precio_billete: 1000, fracciones_totales: 1, cantidad_billetes: 1, premios: []})
      assert s1.id != s2.id
    end

    test "nueva_instancia/1 acepta premios como string separado por comas" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Sorteo String",
        precio_billete: 5000,
        fracciones_totales: 1,
        cantidad_billetes: 3,
        premios: "Primer Premio, Segundo Premio"
      })

      assert length(sorteo.premios) == 2
      assert Enum.all?(sorteo.premios, fn p -> is_map(p) and Map.has_key?(p, :nombre) end)
    end

    test "nueva_instancia/1 acepta premios como lista de mapas" do
      premios = [
        %{nombre: "Primer Premio", valor: 100_000},
        %{nombre: "Segundo Premio", valor: 50_000}
      ]

      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Sorteo Lista",
        precio_billete: 5000,
        fracciones_totales: 1,
        cantidad_billetes: 3,
        premios: premios
      })

      assert length(sorteo.premios) == 2
    end

    test "seleccionar_ganadores/1 cambia el estado a :realizado" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Sorteo Ganadores",
        precio_billete: 5000,
        fracciones_totales: 1,
        cantidad_billetes: 10,
        premios: [%{nombre: "Premio Único", valor: 50_000}]
      })

      resultado = Sorteo.seleccionar_ganadores(sorteo)
      assert resultado.estado == :realizado
    end

    test "seleccionar_ganadores/1 asigna un ganador por cada premio" do
      premios = [
        %{nombre: "Primer Premio", valor: 100_000},
        %{nombre: "Segundo Premio", valor: 50_000},
        %{nombre: "Tercer Premio", valor: 25_000}
      ]

      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Multi Premio",
        precio_billete: 5000,
        fracciones_totales: 1,
        cantidad_billetes: 10,
        premios: premios
      })

      resultado = Sorteo.seleccionar_ganadores(sorteo)
      assert length(resultado.ganadores) == 3
    end

    test "seleccionar_ganadores/1 incluye numero_ganador, premio y valor en cada ganador" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Campos Ganador",
        precio_billete: 1000,
        fracciones_totales: 1,
        cantidad_billetes: 5,
        premios: [%{nombre: "Premio", valor: 10_000}]
      })

      resultado = Sorteo.seleccionar_ganadores(sorteo)
      [ganador] = resultado.ganadores

      assert Map.has_key?(ganador, :numero_ganador)
      assert Map.has_key?(ganador, :premio)
      assert Map.has_key?(ganador, :valor)
    end

    test "verificar_ganador/2 detecta el billete ganador correctamente" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Verificar Test",
        precio_billete: 1000,
        fracciones_totales: 1,
        cantidad_billetes: 5,
        premios: [%{nombre: "Premio", valor: 10_000}]
      })

      finalizado = Sorteo.seleccionar_ganadores(sorteo)
      [ganador | _] = finalizado.ganadores

      assert {:ganador, _} = Sorteo.verificar_ganador(finalizado, ganador.numero_ganador)
    end

    test "verificar_ganador/2 retorna :no_ganador para billete no premiado" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "No Ganador Test",
        precio_billete: 1000,
        fracciones_totales: 1,
        cantidad_billetes: 5,
        premios: [%{nombre: "Premio", valor: 10_000}]
      })

      finalizado = Sorteo.seleccionar_ganadores(sorteo)
      assert :no_ganador == Sorteo.verificar_ganador(finalizado, "999")
    end
  end
end
