defmodule ApuestaTest do
  use ExUnit.Case, async: false

  alias Azar.Apuesta

  describe "Azar.Apuesta" do
    test "nueva/1 crea una apuesta con todos los campos correctos" do
      apuesta = Apuesta.nueva(%{
        jugador_id: "123456",
        sorteo_id: 999,
        numero_billete: "005",
        fracciones: 2,
        monto: 10_000
      })

      assert apuesta.jugador_id == "123456"
      assert apuesta.sorteo_id == 999
      assert apuesta.numero_billete == "005"
      assert apuesta.fracciones == 2
      assert apuesta.monto == 10_000
      assert apuesta.estado == :activa
      assert is_binary(apuesta.id)
    end

    test "nueva/1 genera IDs únicos para distintas apuestas" do
      attrs = %{jugador_id: "123", sorteo_id: 1, numero_billete: "001", fracciones: 1, monto: 1000}
      a1 = Apuesta.nueva(attrs)
      a2 = Apuesta.nueva(attrs)
      assert a1.id != a2.id
    end

    test "nueva/1 asigna estado :activa por defecto" do
      apuesta = Apuesta.nueva(%{
        jugador_id: "abc",
        sorteo_id: 1,
        numero_billete: "001",
        fracciones: 1,
        monto: 5000
      })

      assert apuesta.estado == :activa
    end

    test "nueva/1 registra la fecha de creación" do
      apuesta = Apuesta.nueva(%{
        jugador_id: "abc",
        sorteo_id: 1,
        numero_billete: "001",
        fracciones: 1,
        monto: 5000
      })

      assert apuesta.fecha != nil
      assert is_binary(apuesta.fecha)
    end

    test "historial_jugador/1 retorna solo las apuestas del jugador indicado" do
  archivo_tmp = "apuestas_test_#{:rand.uniform(999_999)}.json"
  jugador_id = "jugador_test_historial"

  on_exit(fn -> File.rm(archivo_tmp) end)

  apuesta_correcta = Apuesta.nueva(%{
    jugador_id: jugador_id,
    sorteo_id: 1,
    numero_billete: "001",
    fracciones: 1,
    monto: 5000
  })

  apuesta_otro = Apuesta.nueva(%{
    jugador_id: "otro_jugador",
    sorteo_id: 1,
    numero_billete: "002",
    fracciones: 1,
    monto: 3000
  })

  Apuesta.guardar_apuestas([apuesta_correcta, apuesta_otro], archivo_tmp)

  resultado = Apuesta.historial_jugador(jugador_id, archivo_tmp)

  assert length(resultado) == 1
  assert Enum.all?(resultado, fn a -> a.jugador_id == jugador_id end)
end

    test "total_gastado/1 retorna 0 para jugador sin apuestas" do
      total = Apuesta.total_gastado("jugador_inexistente_xyz")
      assert total == 0
    end
  end
end
