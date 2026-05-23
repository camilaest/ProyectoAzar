defmodule Azar.SorteoTest do
  use ExUnit.Case, async: true

  alias Azar.Sorteo

  describe "nueva_instancia/1" do
    test "crea un sorteo con billetes generados" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Sorteo Test",
        fecha: "2026-06-01",
        precio_billete: 1000,
        fracciones_totales: 5,
        cantidad_billetes: 10,
        premios: [%{"nombre" => "Primer premio", "valor" => 5000}]
      })

      assert sorteo.nombre == "Sorteo Test"
      assert sorteo.estado == :pendiente
      assert sorteo.id != nil
      assert map_size(sorteo.billetes) == 10
      assert sorteo.billetes["001"].fracciones_disponibles == 5
    end
  end

  describe "seleccionar_ganadores/1" do
    test "genera ganadores y cambia estado a realizado" do
      sorteo = Sorteo.nueva_instancia(%{
        nombre: "Sorteo Cierre",
        fecha: "2026-06-01",
        precio_billete: 500,
        fracciones_totales: 3,
        cantidad_billetes: 5,
        premios: [
          %{"nombre" => "1er lugar", "valor" => 10000},
          %{"nombre" => "2do lugar", "valor" => 5000}
        ]
      })

      resultado = Sorteo.seleccionar_ganadores(sorteo)

      assert resultado.estado == :realizado
      assert length(resultado.ganadores) == 2
    end
  end

  describe "precio_fraccion/1" do
    test "calcula correctamente el precio por fracción" do
      sorteo = %Sorteo{precio_billete: 1000, fracciones_totales: 5}
      assert Sorteo.precio_fraccion(sorteo) == 200.0
    end

    test "retorna precio completo si fracciones es 0" do
      sorteo = %Sorteo{precio_billete: 1000, fracciones_totales: 0}
      assert Sorteo.precio_fraccion(sorteo) == 1000
    end
  end
end
