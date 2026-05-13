defmodule Azar.Billete do
  @moduledoc """
  Módulo que define la estructura y la lógica de negocio para los billetes y fracciones.
  Cada billete pertenece a un sorteo y puede venderse completo o por fracciones.

  - fecha: Mayo del 2026
  - Licencia: GNU GPL v3
  """

  @derive {Jason.Encoder, only: [:numero, :sorteo_id, :fracciones_disponibles, :fracciones_vendidas, :compradores]}
  defstruct [
    numero: nil,                  # Número único del billete (ej: "001")
    sorteo_id: nil,               # ID del sorteo al que pertenece
    fracciones_disponibles: 0,    # Fracciones que quedan por vender
    fracciones_vendidas: 0,       # Fracciones ya vendidas
    compradores: []               # Lista de %{jugador_id, fracciones, monto}
  ]

  # ===========================================================================
  # API Pública
  # ===========================================================================

  @doc """
  Crea un billete nuevo para un sorteo dado.

  ## Parámetros
    - numero: número único del billete (string, ej: "001")
    - sorteo_id: ID del sorteo al que pertenece
    - fracciones_totales: cantidad de fracciones que tiene el billete
  """
  def nuevo(numero, sorteo_id, fracciones_totales) do
    %__MODULE__{
      numero: numero,
      sorteo_id: sorteo_id,
      fracciones_disponibles: fracciones_totales,
      fracciones_vendidas: 0,
      compradores: []
    }
  end

  @doc """
  Verifica si un billete tiene fracciones disponibles para comprar.
  """
  def disponible?(%__MODULE__{fracciones_disponibles: disponibles}), do: disponibles > 0

  @doc """
  Verifica si hay suficientes fracciones disponibles para la cantidad solicitada.
  """
  def fracciones_suficientes?(%__MODULE__{fracciones_disponibles: disponibles}, cantidad) do
    disponibles >= cantidad
  end

  @doc """
  Registra la compra de fracciones en el billete.
  Devuelve {:ok, billete_actualizado} o {:error, razon}.

  Esta función es pura — no genera efectos secundarios.
  La persistencia la maneja el GenServer (SorteoServer).
  """
  def registrar_compra(%__MODULE__{} = billete, jugador_id, cantidad, monto_por_fraccion) do
    cond do
      not disponible?(billete) ->
        {:error, "El billete #{billete.numero} no tiene fracciones disponibles"}

      not fracciones_suficientes?(billete, cantidad) ->
        {:error, "Solo quedan #{billete.fracciones_disponibles} fraccion(es) disponibles"}

      true ->
        comprador = %{
          jugador_id: jugador_id,
          fracciones: cantidad,
          monto: monto_por_fraccion * cantidad
        }

        billete_actualizado = %{billete |
          fracciones_disponibles: billete.fracciones_disponibles - cantidad,
          fracciones_vendidas: billete.fracciones_vendidas + cantidad,
          compradores: billete.compradores ++ [comprador]
        }

        {:ok, billete_actualizado}
    end
  end

  @doc """
  Convierte un mapa (de JSON decodificado) en un struct %Azar.Billete{}.
  """
  def desde_mapa(mapa) when is_map(mapa) do
    atomizado = for {k, v} <- mapa, into: %{}, do: {String.to_atom(to_string(k)), v}

    compradores = case atomizado[:compradores] do
      nil -> []
      lista ->
        Enum.map(lista, fn c ->
          for {k, v} <- c, into: %{}, do: {String.to_atom(to_string(k)), v}
        end)
    end

    struct(__MODULE__, %{atomizado | compradores: compradores})
  end
end
