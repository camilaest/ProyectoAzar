defmodule Azar.Apuesta do
  @moduledoc """
  Módulo que define la estructura y la lógica de negocio para las apuestas.
  Cada apuesta representa la compra de un billete completo o fracción de un sorteo.

  - fecha: Mayo del 2026
  - Licencia: GNU GPL v3
  """

  @derive {Jason.Encoder, only: [:id, :jugador_id, :sorteo_id, :numero_billete, :fracciones, :monto, :fecha, :estado]}
  defstruct [
    id: nil,             # Identificador único de la apuesta
    jugador_id: nil,     # Identificación del jugador que apuesta
    sorteo_id: nil,      # ID del sorteo al que corresponde
    numero_billete: nil, # Número del billete comprado
    fracciones: 1,       # Cantidad de fracciones compradas (1 = billete completo)
    monto: 0,            # Valor pagado
    fecha: nil,          # Fecha/hora de la compra
    estado: :activa      # :activa | :devuelta
  ]

  @archivo_apuestas "apuestas.json"

  # ===========================================================================
  # API Pública
  # ===========================================================================

  @doc """
  Crea una nueva apuesta con los atributos dados.

  ## Parámetros
    - attrs: mapa con jugador_id, sorteo_id, numero_billete, fracciones, monto

  ## Ejemplo
      iex> Azar.Apuesta.nueva(%{jugador_id: "123", sorteo_id: 1, numero_billete: "005", fracciones: 1, monto: 5000})
  """
  def nueva(attrs) do
    %__MODULE__{
      id: generar_id(),
      jugador_id: Map.fetch!(attrs, :jugador_id),
      sorteo_id: Map.fetch!(attrs, :sorteo_id),
      numero_billete: Map.fetch!(attrs, :numero_billete),
      fracciones: Map.get(attrs, :fracciones, 1),
      monto: Map.fetch!(attrs, :monto),
      fecha: DateTime.utc_now() |> DateTime.to_string(),
      estado: :activa
    }
  end

  @doc """
  Carga todas las apuestas desde el archivo JSON.
  Devuelve una lista vacía si el archivo no existe.
  """
  def cargar_apuestas(archivo \\ @archivo_apuestas) do
    case File.read(archivo) do
      {:ok, contenido} ->
        contenido
        |> Jason.decode!()
        |> Enum.map(&convertir_a_struct/1)

      {:error, :enoent} ->
        []
    end
  end

  @doc """
  Guarda la lista completa de apuestas en el archivo JSON.
  """
  def guardar_apuestas(apuestas, archivo \\ @archivo_apuestas) do
    apuestas
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode!(pretty: true)
    |> (&File.write(archivo, &1)).()
  end

  @doc """
  Devuelve todas las apuestas activas de un jugador específico.
  """
  def historial_jugador(jugador_id, archivo \\ @archivo_apuestas) do
    cargar_apuestas(archivo)
    |> Enum.filter(fn a -> a.jugador_id == jugador_id end)
  end

  @doc """
  Calcula el total gastado por un jugador en apuestas activas.
  """
  def total_gastado(jugador_id, archivo \\ @archivo_apuestas) do
    historial_jugador(jugador_id, archivo)
    |> Enum.filter(fn a -> a.estado == :activa end)
    |> Enum.reduce(0, fn a, acc -> acc + a.monto end)
  end

  @doc """
  Marca una apuesta como devuelta (si el sorteo aún no se realizó).
  Devuelve {:ok, apuesta_actualizada} o {:error, razon}.
  """
  def devolver(apuesta_id, archivo \\ @archivo_apuestas) do
    apuestas = cargar_apuestas(archivo)

    case Enum.find(apuestas, fn a -> a.id == apuesta_id end) do
      nil ->
        {:error, "Apuesta no encontrada"}

      %{estado: :devuelta} ->
        {:error, "La apuesta ya fue devuelta"}

      apuesta ->
        actualizada = %{apuesta | estado: :devuelta}
        nueva_lista = Enum.map(apuestas, fn a ->
          if a.id == apuesta_id, do: actualizada, else: a
        end)
        guardar_apuestas(nueva_lista, archivo)
        {:ok, actualizada}
    end
  end

  # ===========================================================================
  # Funciones privadas
  # ===========================================================================

  defp generar_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16() |> String.downcase()
  end

  defp convertir_a_struct(mapa) do
    atomizado = for {k, v} <- mapa, into: %{}, do: {String.to_atom(k), v}
    estado = case atomizado[:estado] do
      "activa"   -> :activa
      "devuelta" -> :devuelta
      otro       -> String.to_atom(to_string(otro))
    end
    struct(__MODULE__, %{atomizado | estado: estado})
  end
end
