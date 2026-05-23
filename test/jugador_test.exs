defmodule Azar.JugadorTest do
  use ExUnit.Case, async: true

  alias Azar.Jugador

  describe "crear/4" do
    test "crea un jugador con los campos correctos" do
      jugador = Jugador.crear("Test", "123", "pass", "4111111111111111")

      assert jugador.nombre == "Test"
      assert jugador.identificacion == "123"
      assert jugador.saldo == 0.0
      assert jugador.premios_ganados == []
    end
  end

  describe "actualizar_saldo/2" do
    test "suma saldo correctamente" do
      jugador = Jugador.crear("Test", "123", "pass", "4111111111111111")
      {:ok, actualizado} = Jugador.actualizar_saldo(jugador, 500.0)
      assert actualizado.saldo == 500.0
    end

    test "resta saldo correctamente" do
      jugador = %{Jugador.crear("Test", "123", "pass", "4111111111111111") | saldo: 1000.0}
      {:ok, actualizado} = Jugador.actualizar_saldo(jugador, -300.0)
      assert actualizado.saldo == 700.0
    end

    test "no permite saldo negativo" do
      jugador = Jugador.crear("Test", "123", "pass", "4111111111111111")
      assert {:error, "Saldo insuficiente"} = Jugador.actualizar_saldo(jugador, -100.0)
    end
  end

  describe "agregar_premio/2" do
    test "agrega un premio al historial" do
      jugador = Jugador.crear("Test", "123", "pass", "4111111111111111")
      actualizado = Jugador.agregar_premio(jugador, %{premio: "1er lugar", valor: 5000})
      assert length(actualizado.premios_ganados) == 1
    end
  end

  describe "validar_lista/1" do
    test "elimina duplicados por identificación" do
      jugadores = [
        Jugador.crear("A", "123", "p1", "4111111111111111"),
        Jugador.crear("B", "123", "p2", "4222222222222222"),
        Jugador.crear("C", "456", "p3", "4333333333333333")
      ]

      resultado = Jugador.validar_lista(jugadores)
      assert length(resultado) == 2
    end

    test "elimina jugadores con campos vacíos" do
      jugadores = [
        Jugador.crear("A", "123", "p1", "4111111111111111"),
        Jugador.crear("", "456", "p2", "4222222222222222")
      ]

      resultado = Jugador.validar_lista(jugadores)
      assert length(resultado) == 1
    end
  end
end
