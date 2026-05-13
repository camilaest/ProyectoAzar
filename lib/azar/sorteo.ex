defmodule Azar.Sorteo do
  @moduledoc """
  Define la estructura de datos y la lógica de negocio para los sorteos de Azar S.A.
  """

  @derive {Jason.Encoder, only: [:id, :nombre, :fecha, :precio_billete, :fracciones_totales, :cantidad_billetes, :premios, :billetes, :estado]}
  defstruct [
    id: nil,                  # Un identificador único (ej: "SOR-101")
    nombre: "",               # Nombre del sorteo
    fecha: nil,               # Fecha programada [cite: 28]
    precio_billete: 0,        # Valor del billete completo
    fracciones_totales: 0,    # Cantidad de fracciones por billete [cite: 30]
    cantidad_billetes: 0,     # Cuántos billetes existen (con número único) [cite: 31]
    premios: [],              # Lista de premios asociados [cite: 34, 60]
    billetes: %{},            # Mapa para rastrear quién compró qué número
    estado: :pendiente        # :pendiente, :realizado o :cancelado [cite: 35]
  ]

  @premios ["1er puesto", "2do puesto", "3er puesto"]

  @doc """
  Recibe una lista de jugadores limpia y retorna los ganadores con su premio.
  Si hay menos jugadores que premios, asigna un premio por jugador disponible.
  """
  def sortear(jugadores) when is_list(jugadores) do
    jugadores
    |> Enum.shuffle()
    |> Enum.take(min(length(jugadores), length(@premios)))
    |> Enum.with_index()
    |> Enum.map(fn {jugador, indice} ->
      %{
        nombre: obtener_nombre(jugador),
        premio: Enum.at(@premios, indice)
      }
    end)
  end

  defp obtener_nombre(%{nombre: nombre}) when is_binary(nombre), do: nombre
  defp obtener_nombre(nombre) when is_binary(nombre), do: nombre
  defp obtener_nombre(_), do: "Desconocido"
end
