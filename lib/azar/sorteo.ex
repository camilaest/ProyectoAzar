defmodule Azar.Sorteo do
  @moduledoc """
  Define la estructura de datos para un sorteo de Azar S.A.
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
end
