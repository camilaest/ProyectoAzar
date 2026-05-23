defmodule Azar.Apuesta do
  @moduledoc """
  Módulo para la gestión de apuestas en Azar S.A.
  Registra compras de billetes/fracciones y permite consultar historial.
  """

  @derive {Jason.Encoder,
           only: [:id, :jugador_id, :sorteo_id, :numero_billete, :fracciones, :monto, :fecha]}

  defstruct id: nil,
            jugador_id: "",
            sorteo_id: nil,
            numero_billete: "",
            fracciones: 0,
            monto: 0.0,
            fecha: nil

  alias Azar.Logger

  @archivo_apuestas "apuestas.json"

  # ════════════════════════════════════════════
  # Crear Apuesta
  # ════════════════════════════════════════════

  @doc """
  Registra una nueva apuesta después de una compra exitosa.
  """
  def registrar_apuesta(jugador_id, sorteo_id, numero_billete, fracciones, monto) do
    apuesta = %__MODULE__{
      id: :rand.uniform(999_999),
      jugador_id: jugador_id,
      sorteo_id: sorteo_id,
      numero_billete: numero_billete,
      fracciones: fracciones,
      monto: monto,
      fecha: DateTime.utc_now() |> DateTime.to_string()
    }

    # Guardar en archivo
    apuestas = cargar_apuestas()
    nuevas = apuestas ++ [apuesta]
    guardar_apuestas(nuevas)

    Logger.registrar(
      "Registrar apuesta",
      "Apuesta #{apuesta.id} - Jugador #{jugador_id} - Sorteo #{sorteo_id} - Billete #{numero_billete}"
    )

    {:ok, apuesta}
  end

  # ════════════════════════════════════════════
  # Consultas
  # ════════════════════════════════════════════

  @doc "Obtiene todas las apuestas de un jugador específico."
  def historial_por_jugador(jugador_id) do
    cargar_apuestas()
    |> Enum.filter(fn a -> a.jugador_id == jugador_id end)
  end

  @doc "Obtiene todas las apuestas de un sorteo específico."
  def apuestas_por_sorteo(sorteo_id) do
    cargar_apuestas()
    |> Enum.filter(fn a -> a.sorteo_id == sorteo_id end)
  end

  @doc "Obtiene todas las apuestas."
  def listar_todas do
    cargar_apuestas()
  end

  # ════════════════════════════════════════════
  # Verificación de Premios
  # ════════════════════════════════════════════

  @doc """
  Verifica si un jugador ganó algún premio en un sorteo cerrado.
  Retorna lista de premios ganados (puede ser vacía).
  """
  def verificar_premios(jugador_id, sorteo) do
    # Obtener los billetes que compró el jugador en este sorteo
    apuestas_jugador =
      cargar_apuestas()
      |> Enum.filter(fn a ->
        a.jugador_id == jugador_id and a.sorteo_id == sorteo.id
      end)

    numeros_comprados = Enum.map(apuestas_jugador, fn a -> a.numero_billete end)

    # Verificar contra los ganadores
    sorteo.ganadores
    |> Enum.filter(fn ganador ->
      numero = Map.get(ganador, "numero_ganador") || Map.get(ganador, :numero_ganador)
      numero in numeros_comprados
    end)
    |> Enum.map(fn ganador ->
      %{
        premio: Map.get(ganador, "premio") || Map.get(ganador, :premio),
        valor: Map.get(ganador, "valor") || Map.get(ganador, :valor),
        numero: Map.get(ganador, "numero_ganador") || Map.get(ganador, :numero_ganador)
      }
    end)
  end

  # ════════════════════════════════════════════
  # Persistencia
  # ════════════════════════════════════════════

  defp guardar_apuestas(apuestas) do
    apuestas
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode!(pretty: true)
    |> (&File.write!(@archivo_apuestas, &1)).()
  end

  def cargar_apuestas do
    case File.read(@archivo_apuestas) do
      {:ok, contenido} ->
        contenido
        |> Jason.decode!()
        |> Enum.map(fn mapa ->
          datos = for {k, v} <- mapa, into: %{}, do: {String.to_atom(k), v}
          struct(__MODULE__, datos)
        end)

      {:error, :enoent} ->
        []
    end
  end
end
