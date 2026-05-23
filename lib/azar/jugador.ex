defmodule Azar.Jugador do
  @moduledoc """
  Módulo para la gestión de jugadores de Azar S.A.
  Incluye struct, CRUD, persistencia JSON, validación, saldo y premios.
  """

  @derive {Jason.Encoder,
           only: [
             :nombre,
             :identificacion,
             :contrasena,
             :tarjetaCredito,
             :saldo,
             :premios_ganados
           ]}

  defstruct nombre: "",
            identificacion: "",
            contrasena: "",
            tarjetaCredito: "",
            saldo: 0.0,
            premios_ganados: []

  alias Azar.Util

  @archivo_jugadores "jugadores.json"

  # ─── Creación ───

  @doc "Crea un jugador con los datos proporcionados."
  def crear(nombre, identificacion, contrasena, tarjetaCredito) do
    %__MODULE__{
      nombre: nombre,
      identificacion: identificacion,
      contrasena: contrasena,
      tarjetaCredito: tarjetaCredito,
      saldo: 0.0,
      premios_ganados: []
    }
  end

  # ─── Saldo ───

  @doc "Actualiza el saldo de un jugador sumando (o restando si es negativo) el monto."
  def actualizar_saldo(jugador, monto) when is_number(monto) do
    nuevo_saldo = jugador.saldo + monto

    if nuevo_saldo < 0 do
      {:error, "Saldo insuficiente"}
    else
      {:ok, %{jugador | saldo: nuevo_saldo}}
    end
  end

  @doc "Agrega un premio ganado al historial del jugador."
  def agregar_premio(jugador, premio) do
    %{jugador | premios_ganados: jugador.premios_ganados ++ [premio]}
  end

  # ─── Ingreso interactivo ───

  def ingresar(mensaje) do
    Util.mostrar_mensaje(mensaje)

    nombre = Util.ingresar("Ingrese su nombre completo: ", :texto)
    identificacion = Util.ingresar("Ingrese su número de identificación: ", :texto)
    contrasena = Util.ingresar("Ingrese su contraseña: ", :texto)
    tarjetaCredito = Util.ingresar("Ingrese el número de su tarjeta de crédito: ", :texto)

    crear(nombre, identificacion, contrasena, tarjetaCredito)
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

  # ─── Persistencia JSON ───

  def escribir_json(jugadores, nombre \\ @archivo_jugadores) do
    jugadores
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode!(pretty: true)
    |> (&File.write(nombre, &1)).()
  end

  @doc "Guarda la lista completa de jugadores en el JSON (reescribe todo el archivo)."
  def guardar_todos(jugadores) do
    escribir_json(jugadores, @archivo_jugadores)
  end

  @doc "Actualiza un jugador específico en el archivo JSON (por identificación)."
  def actualizar_en_json(jugador_actualizado) do
    jugadores = cargar_jugadores()

    nuevos =
      Enum.map(jugadores, fn j ->
        if j.identificacion == jugador_actualizado.identificacion do
          jugador_actualizado
        else
          j
        end
      end)

    guardar_todos(nuevos)
    {:ok, jugador_actualizado}
  end

  def cargar_jugadores(nombre_archivo \\ @archivo_jugadores) do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        contenido
        |> Jason.decode!()
        |> Enum.map(fn mapa ->
          datos =
            for {k, v} <- mapa, into: %{} do
              {String.to_atom(k), v}
            end

          # Asegurar que saldo sea float y premios_ganados sea lista
          datos =
            datos
            |> Map.put_new(:saldo, 0.0)
            |> Map.put_new(:premios_ganados, [])
            |> Map.update(:saldo, 0.0, fn
              s when is_binary(s) -> String.to_float(s)
              s when is_integer(s) -> s * 1.0
              s -> s
            end)

          struct(__MODULE__, datos)
        end)

      {:error, :enoent} ->
        # Si el archivo no existe, devolvemos lista vacía para que el programa siga
        []
    end
  end

  @doc "Busca un jugador por identificación."
  def buscar_por_id(identificacion) do
    jugadores = cargar_jugadores()
    Enum.find(jugadores, fn j -> j.identificacion == identificacion end)
  end

  # Validar que no haya jugadores con la misma identificación y que no haya campos vacíos o jugadores que no existen

  def validar_lista(jugadores) do
    jugadores
    |> Enum.uniq_by(fn j -> j.identificacion end)
    |> Enum.filter(fn j -> j.nombre != "" and j.identificacion != "" end)
  end
end
