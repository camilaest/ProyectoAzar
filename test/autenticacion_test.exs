defmodule Azar.AutenticacionTest do
  use ExUnit.Case, async: false

  alias Azar.Autenticacion

  describe "validar_tarjeta/1" do
    test "acepta tarjeta válida de 16 dígitos" do
      assert :ok = Autenticacion.validar_tarjeta("4111111111111111")
    end

    test "rechaza tarjeta con letras" do
      assert {:error, _} = Autenticacion.validar_tarjeta("4111abcd11111111")
    end

    test "rechaza tarjeta muy corta" do
      assert {:error, _} = Autenticacion.validar_tarjeta("411111")
    end
  end
end
