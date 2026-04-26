defmodule Azar.Jugador do
  defstruct nombre: "", identificacion: "", contraseña: "", tarjetaCredito: ""

  alias Azar.Util

  # Función para crear un jugador
  def crear(nombre, identificacion, contraseña, tarjetaCredito) do
    %__MODULE__{
      nombre: nombre,
      identificacion: identificacion,
      contraseña: contraseña,
      tarjetaCredito: tarjetaCredito
    }
  end

  def ingresar(mensaje) do
    Util.mostrar_mensaje(mensaje)

    nombre = Util.ingresar("Ingrese su nombre completo: ", :texto)
    identificacion = Util.ingresar("Ingrese su número de identificación: ", :texto)
    contraseña = Util.ingresar("Ingrese su contraseña: ", :texto)
    tarjetaCredito = Util.ingresar("Ingrese el número de su tarjeta de crédito: ", :texto)

    crear(nombre, identificacion, contraseña, tarjetaCredito)
  end

  def ingresar(mensaje, :jugadores) do
    ingresar(mensaje, [], :jugadores)
  end

  defp ingresar(mensaje, lista, :jugadores) do
    jugador = ingresar(mensaje)
    nueva_lista = lista ++ [jugador]

    mas_jugadores = Util.ingresar("\nDesea ingresar más jugadores (si/no)?: ", :boolean)

    case mas_jugadores do
      true -> ingresar(mensaje, nueva_lista, :jugadores)
      false -> nueva_lista
    end
  end

  def escribir_json(jugadores, nombre) do
    jugadores
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode!()
    |> (&File.write(nombre, &1)).()
  end
end
