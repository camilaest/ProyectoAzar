defmodule JugadorTest do
  use ExUnit.Case, async: false

  alias Azar.Jugador

  describe "Azar.Jugador" do
    test "crear/4 genera un struct con los datos correctos" do
      jugador = Jugador.crear("María López", "12345678", "clave123", "4111111111111111")

      assert jugador.nombre == "María López"
      assert jugador.identificacion == "12345678"
      assert jugador.contraseña == "clave123"
      assert jugador.tarjetaCredito == "4111111111111111"
    end

    test "crear/4 permite nombres con caracteres especiales" do
      jugador = Jugador.crear("José Ángel Muñoz", "98765432", "pass", "1234")
      assert jugador.nombre == "José Ángel Muñoz"
    end

    test "validar_lista/1 elimina duplicados por identificacion" do
      jugadores = [
        Jugador.crear("Ana", "001", "pass", "1234"),
        Jugador.crear("Ana Copia", "001", "pass2", "5678"),
        Jugador.crear("Carlos", "002", "pass", "9012")
      ]

      validados = Jugador.validar_lista(jugadores)
      assert length(validados) == 2
    end

    test "validar_lista/1 filtra jugadores con nombre vacío" do
      jugadores = [
        Jugador.crear("", "001", "pass", "1234"),
        Jugador.crear("Ana", "002", "pass", "5678")
      ]

      validados = Jugador.validar_lista(jugadores)
      assert length(validados) == 1
      assert hd(validados).nombre == "Ana"
    end

    test "validar_lista/1 filtra jugadores con identificacion vacía" do
      jugadores = [
        Jugador.crear("Carlos", "", "pass", "1234"),
        Jugador.crear("Ana", "002", "pass", "5678")
      ]

      validados = Jugador.validar_lista(jugadores)
      assert length(validados) == 1
      assert hd(validados).nombre == "Ana"
    end

    test "validar_lista/1 retorna lista vacía si todos son inválidos" do
      jugadores = [
        Jugador.crear("", "001", "pass", "1234"),
        Jugador.crear("Carlos", "", "pass", "5678")
      ]

      validados = Jugador.validar_lista(jugadores)
      assert validados == []
    end

    test "validar_lista/1 retorna la misma lista si todos son válidos" do
      jugadores = [
        Jugador.crear("Ana", "001", "pass", "1234"),
        Jugador.crear("Carlos", "002", "pass", "5678"),
        Jugador.crear("Luis", "003", "pass", "9012")
      ]

      validados = Jugador.validar_lista(jugadores)
      assert length(validados) == 3
    end

    test "cargar_jugadores/1 retorna lista vacía si el archivo no existe" do
      resultado = Jugador.cargar_jugadores("archivo_inexistente.json")
      assert resultado == []
    end
  end
end
