defmodule Azar.Billete do
  @moduledoc """
  Módulo para la gestión de billetes de sorteo en Azar S.A.
  Define la estructura y lógica de billetes y sus fracciones.
  """

  @derive {Jason.Encoder,
           only: [:numero, :sorteo_id, :fracciones_disponibles, :fracciones_vendidas, :compradores]}

  defstruct numero: "",
            sorteo_id: nil,
            fracciones_disponibles: 0,
            fracciones_vendidas: 0,
            compradores: []

  @doc """
  Verifica si un billete tiene fracciones disponibles para comprar.
  """
  def disponible?(billete) do
    billete.fracciones_disponibles > 0
  end

  @doc """
  Verifica si se puede comprar una cantidad específica de fracciones.
  """
  def puede_comprar?(billete, cantidad) do
    billete.fracciones_disponibles >= cantidad
  end

  @doc """
  Registra la compra de fracciones en un billete.
  Retorna el billete actualizado.
  """
  def comprar_fracciones(billete, jugador_id, cantidad) do
    if puede_comprar?(billete, cantidad) do
      billete_actualizado = %{
        billete
        | fracciones_disponibles: billete.fracciones_disponibles - cantidad,
          fracciones_vendidas: billete.fracciones_vendidas + cantidad,
          compradores: billete.compradores ++ [%{jugador_id: jugador_id, fracciones: cantidad}]
      }

      {:ok, billete_actualizado}
    else
      {:error, "No hay suficientes fracciones disponibles (disponibles: #{billete.fracciones_disponibles})"}
    end
  end

  @doc """
  Obtiene la lista de compradores de un billete.
  """
  def listar_compradores(billete) do
    billete.compradores
  end

  @doc """
  Calcula el porcentaje de fracciones vendidas.
  """
  def porcentaje_vendido(billete) do
    total = billete.fracciones_disponibles + billete.fracciones_vendidas

    if total > 0 do
      (billete.fracciones_vendidas / total * 100) |> Float.round(1)
    else
      0.0
    end
  end
end
