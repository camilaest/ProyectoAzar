defmodule Azar.Util do
  @moduledoc """
  Módulo con funciones utilitarias reutilizables para Azar S.A.
  Incluye I/O, parsing, validaciones y funciones matemáticas.
  - Licencia: GNU GPL v3
  """

  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje, :entero), do: ingresar(mensaje, &String.to_integer/1, :entero)

  def ingresar(mensaje, :real), do: ingresar(mensaje, &String.to_float/1, :real)

  def ingresar(mensaje, :boolean), do: ingresar_booleano(mensaje)

  defp ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(parser, tipo_dato)
    end
  end

  defp ingresar_booleano(mensaje) do
    case mensaje
         |> ingresar(:texto)
         |> String.downcase() do
      "si" -> true
      "sí" -> true
      "s" -> true
      "no" -> false
      "n" -> false
      _ ->
        "Error, se espera que ingrese 'si' o 'no'\n"
        |> mostrar_error()

        ingresar_booleano(mensaje)
    end
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  @doc "Formatea un número como moneda."
  def formatear_moneda(numero) when is_number(numero) do
    "$#{:erlang.float_to_binary(numero * 1.0, decimals: 2)}"
  end

  @doc "Obtiene la fecha actual como string YYYY-MM-DD."
  def fecha_actual do
    Date.utc_today() |> Date.to_string()
  end

  @doc "Obtiene fecha y hora actual como string."
  def fecha_hora_actual do
    DateTime.utc_now() |> DateTime.to_string()
  end

  def calcular_permutaciones_circulares(n) do
    (n - 1)
    |> calcular_factorial()
  end

  def calcular_factorial(0), do: 1
  def calcular_factorial(m), do: m * calcular_factorial(m - 1)
end
