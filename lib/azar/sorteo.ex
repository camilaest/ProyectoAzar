defmodule Azar.Sorteo do
  @moduledoc """
  Define la estructura de datos y la lógica de negocio para los sorteos de Azar S.A.

  Los billetes de cada sorteo se generan automáticamente al crear el sorteo,
  y cada uno empieza con todas sus fracciones disponibles.

  - fecha: Mayo del 2026
  - Licencia: GNU GPL v3
  """

  alias Azar.Billete

  @derive {Jason.Encoder, only: [
    :id, :nombre, :fecha, :precio_billete, :fracciones_totales,
    :cantidad_billetes, :premios, :billetes, :estado, :ganadores, :ingresos_totales
  ]}
  defstruct [
    id: nil,                 # Identificador único numérico
    nombre: "",              # Nombre del sorteo
    fecha: nil,              # Fecha programada (string ISO 8601)
    precio_billete: 0,       # Valor del billete completo
    fracciones_totales: 1,   # Cantidad de fracciones por billete
    cantidad_billetes: 0,    # Total de billetes del sorteo
    premios: [],             # Lista de %{nombre, valor}
    billetes: %{},           # Mapa numero -> %Billete{}
    estado: :pendiente,      # :pendiente | :realizado | :cancelado
    ganadores: [],           # Lista de ganadores al cerrar el sorteo
    ingresos_totales: 0      # Total recaudado
  ]

  # ===========================================================================
  # API Pública
  # ===========================================================================

  @doc """
  Crea una nueva instancia de sorteo con ID único y billetes generados.

  ## Ejemplo
      attrs = %{nombre: "Gran Rifa", precio_billete: 5000, fracciones_totales: 2, cantidad_billetes: 10, premios: [...]}
      sorteo = Azar.Sorteo.nueva_instancia(attrs)
  """
  def nueva_instancia(attrs) do
    id = generar_id()
    cantidad = Map.get(attrs, :cantidad_billetes, 10)
    fracciones = Map.get(attrs, :fracciones_totales, 1)

    billetes = generar_billetes(id, cantidad, fracciones)

    %__MODULE__{
      id: id,
      nombre: Map.get(attrs, :nombre, "Sorteo Sin Nombre"),
      fecha: Map.get(attrs, :fecha, nil),
      precio_billete: Map.get(attrs, :precio_billete, 0),
      fracciones_totales: fracciones,
      cantidad_billetes: cantidad,
      premios: normalizar_premios(Map.get(attrs, :premios, [])),
      billetes: billetes,
      estado: :pendiente,
      ganadores: [],
      ingresos_totales: 0
    }
  end

  @doc """
  Selecciona ganadores de forma aleatoria al cerrar un sorteo.
  Por cada premio, asigna un número de billete ganador distinto.

  Devuelve el sorteo con estado :realizado y lista de ganadores.
  """
  def seleccionar_ganadores(%__MODULE__{} = sorteo) do
    numeros_disponibles =
      sorteo.billetes
      |> Map.keys()
      |> Enum.shuffle()

    ganadores =
      sorteo.premios
      |> Enum.with_index()
      |> Enum.map(fn {premio, indice} ->
        %{
          numero_ganador: Enum.at(numeros_disponibles, rem(indice, length(numeros_disponibles))),
          premio: Map.get(premio, :nombre, Map.get(premio, "nombre", "Premio #{indice + 1}")),
          valor: Map.get(premio, :valor, Map.get(premio, "valor", 0))
        }
      end)

    %{sorteo | estado: :realizado, ganadores: ganadores}
  end

  @doc """
  Verifica si un número de billete es ganador en este sorteo.
  Devuelve {:ganador, premio} o :no_ganador.
  """
  def verificar_ganador(%__MODULE__{ganadores: ganadores}, numero_billete) do
    case Enum.find(ganadores, fn g ->
      to_string(g.numero_ganador) == to_string(numero_billete)
    end) do
      nil -> :no_ganador
      ganador -> {:ganador, ganador}
    end
  end

  # ===========================================================================
  # Funciones privadas
  # ===========================================================================

  defp generar_id, do: :rand.uniform(999_999)

  # Genera los billetes del sorteo con número formateado (ej: "001", "002", ...)
  defp generar_billetes(sorteo_id, cantidad, fracciones) do
    1..cantidad
    |> Enum.map(fn n ->
      numero = String.pad_leading(to_string(n), 3, "0")
      billete = Billete.nuevo(numero, sorteo_id, fracciones)
      {numero, billete}
    end)
    |> Enum.into(%{})
  end

  # Normaliza la lista de premios: acepta listas de mapas o strings.
  defp normalizar_premios(premios) when is_list(premios) do
    Enum.map(premios, fn
      %{nombre: _, valor: _} = p -> p
      %{"nombre" => nombre, "valor" => valor} -> %{nombre: nombre, valor: valor}
      nombre when is_binary(nombre) -> %{nombre: nombre, valor: 0}
      otro -> otro
    end)
  end
  defp normalizar_premios(premios) when is_binary(premios) do
    premios
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn nombre -> %{nombre: nombre, valor: 0} end)
  end
  defp normalizar_premios(_), do: []
end
