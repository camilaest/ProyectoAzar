defmodule Azar.Autenticacion do
  @moduledoc """
  Módulo de autenticación para jugadores de Azar S.A.
  Maneja registro, inicio de sesión y validaciones.
  """

  alias Azar.Jugador
  alias Azar.Logger

  @doc """
  Registra un nuevo jugador validando que no exista (por identificación).
  Retorna {:ok, jugador} o {:error, razón}.
  """
  def registrar(nombre, identificacion, contraseña, tarjeta_credito) do
    # Validaciones
    with :ok <- validar_campos(nombre, identificacion, contraseña, tarjeta_credito),
         :ok <- validar_contraseña(contraseña),
         :ok <- validar_tarjeta(tarjeta_credito),
         :ok <- validar_no_duplicado(identificacion) do
      nuevo_jugador = Jugador.crear(nombre, identificacion, contraseña, tarjeta_credito)

      # Cargar jugadores existentes y agregar el nuevo
      jugadores = Jugador.cargar_jugadores()
      nuevos_jugadores = jugadores ++ [nuevo_jugador]
      Jugador.guardar_todos(nuevos_jugadores)

      Logger.registrar("Registro de jugador", "Jugador '#{nombre}' registrado exitosamente")
      {:ok, nuevo_jugador}
    end
  end

  @doc """
  Inicia sesión validando identificación y contraseña.
  Retorna {:ok, jugador} o {:error, razón}.
  """
  def iniciar_sesion(identificacion, contraseña) do
    jugadores = Jugador.cargar_jugadores()

    case Enum.find(jugadores, fn j -> j.identificacion == identificacion end) do
      nil ->
        Logger.registrar("Inicio de sesión", "Fallido - Jugador no encontrado: #{identificacion}")
        {:error, "Jugador no encontrado con esa identificación"}

      jugador ->
        if jugador.contrasena == contraseña do
          Logger.registrar("Inicio de sesión", "Exitoso - Jugador: #{jugador.nombre}")
          {:ok, jugador}
        else
          Logger.registrar("Inicio de sesión", "Fallido - Contraseña incorrecta para: #{identificacion}")
          {:error, "Contraseña incorrecta"}
        end
    end
  end

  @doc "Validación básica del número de tarjeta de crédito (13-19 dígitos numéricos)."
  def validar_tarjeta(numero) when is_binary(numero) do
    limpio = String.replace(numero, ~r/\s/, "")

    cond do
      not Regex.match?(~r/^\d+$/, limpio) ->
        {:error, "La tarjeta de crédito solo debe contener números"}

      String.length(limpio) < 13 or String.length(limpio) > 19 ->
        {:error, "La tarjeta de crédito debe tener entre 13 y 19 dígitos"}

      true ->
        :ok
    end
  end

  # ─── Validaciones privadas ───

  defp validar_campos(nombre, identificacion, contraseña, tarjeta) do
    campos = [nombre, identificacion, contraseña, tarjeta]

    if Enum.any?(campos, fn c -> c == nil or String.trim(c) == "" end) do
      {:error, "Todos los campos son obligatorios (no pueden estar vacíos)"}
    else
      :ok
    end
  end

  defp validar_contraseña(contraseña) do
    if String.length(contraseña) < 4 do
      {:error, "La contraseña debe tener al menos 4 caracteres"}
    else
      :ok
    end
  end

  defp validar_no_duplicado(identificacion) do
    jugadores = Jugador.cargar_jugadores()

    if Enum.any?(jugadores, fn j -> j.identificacion == identificacion end) do
      {:error, "Ya existe un jugador con la identificación #{identificacion}"}
    else
      :ok
    end
  end
end
