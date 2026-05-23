defmodule Azar.Sorteo do
  @moduledoc """
  Define la estructura de datos y la lógica de negocio para los sorteos de Azar S.A.
  """

  # Configuración para la persistencia en archivos JSON
  @derive {Jason.Encoder,
           only: [
             :id,
             :nombre,
             :fecha,
             :precio_billete,
             :fracciones_totales,
             :cantidad_billetes,
             :premios,
             :billetes,
             :estado,
             :ganadores,
             :ingresos_totales
           ]}

  defstruct id: nil,
            nombre: "",
            fecha: nil,
            precio_billete: 0,
            fracciones_totales: 0,
            cantidad_billetes: 0,
            premios: [],
            billetes: %{},
            estado: :pendiente,
            ganadores: [],
            ingresos_totales: 0

  @doc """
  Crea una nueva instancia de sorteo e inicializa todos los billetes disponibles.
  """
  def nueva_instancia(attrs \\ %{}) do
    # Fusionamos los atributos recibidos con el molde del struct
    sorteo = struct(__MODULE__, attrs)

    # Generamos los billetes automáticamente (ej: del 1 al 100)
    billetes_generados =
      for n <- 1..sorteo.cantidad_billetes, into: %{} do
        # Formateamos el número a 3 dígitos (ej: 1 -> "001")
        numero_str = n |> Integer.to_string() |> String.pad_leading(3, "0")

        {numero_str,
         %{
           numero: numero_str,
           fracciones_disponibles: sorteo.fracciones_totales,
           fracciones_vendidas: 0,
           compradores: []
         }}
      end

    # Retornamos el sorteo con su ID único y sus billetes listos
    %{sorteo | billetes: billetes_generados, id: :rand.uniform(999_999)}
  end

  @doc """
  Algoritmo aleatorio para seleccionar números ganadores y cerrar el sorteo.
  """
  def seleccionar_ganadores(sorteo) do
    # 1. Obtenemos todos los números de billetes que existen
    numeros_disponibles = Map.keys(sorteo.billetes)

    # 2. Seleccionamos números al azar según la cantidad de premios
    cantidad_premios = length(normalizar_premios(sorteo.premios))
    numeros_premiados = Enum.take_random(numeros_disponibles, cantidad_premios)

    # 3. Emparejamos cada premio con un número ganador
    premios_norm = normalizar_premios(sorteo.premios)

    resultados =
      Enum.zip(premios_norm, numeros_premiados)
      |> Enum.map(fn {premio, numero} ->
        billete = Map.get(sorteo.billetes, numero, %{compradores: []})
        compradores_billete = Map.get(billete, :compradores, [])

        %{
          "premio" => obtener_campo(premio, "nombre"),
          "valor" => obtener_campo(premio, "valor"),
          "numero_ganador" => numero,
          "compradores" => compradores_billete
        }
      end)

    # 4. Actualizamos el estado del sorteo
    %{sorteo | ganadores: resultados, estado: :realizado}
  end

  @doc "Calcula el precio de una fracción individual."
  def precio_fraccion(sorteo) do
    if sorteo.fracciones_totales > 0 do
      sorteo.precio_billete / sorteo.fracciones_totales
    else
      sorteo.precio_billete
    end
  end

  # ─── Helpers privados ───

  # Los premios pueden venir como mapas con llaves string (de JSON) o atom
  defp normalizar_premios(premios) when is_list(premios), do: premios
  defp normalizar_premios(_), do: []

  defp obtener_campo(mapa, campo) when is_map(mapa) do
    Map.get(mapa, campo) || Map.get(mapa, String.to_atom(campo))
  end

  defp obtener_campo(_, _), do: nil
end
