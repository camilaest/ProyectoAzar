defmodule Azar.Apuesta do

  @derive {Jason.Encoder, only: [
    :id,
    :jugador_id,
    :sorteo_id,
    :numero_billete,
    :fracciones,
    :monto,
    :fecha
  ]}
  defstruct [
    id: nil,             # Identificador único de la apuesta (ej: "APU-001")
    jugador_id: nil,     # Identificación del jugador comprador
    sorteo_id: nil,      # ID del sorteo
    numero_billete: nil, # Número del billete comprado
    fracciones: 0,       # Cantidad de fracciones compradas (igual a fracciones_totales = billete completo)
    monto: 0.0,          # Monto total pagado
    fecha: nil           # Fecha y hora de la compra
  ]

  alias Azar.{Billete, Util}

  def nueva(jugador_id, sorteo_id, numero_billete, fracciones, monto) do
    %__MODULE__{
      id: generar_id(),
      jugador_id: jugador_id,
      sorteo_id: sorteo_id,
      numero_billete: numero_billete,
      fracciones: fracciones,
      monto: monto,
      fecha: DateTime.utc_now() |> DateTime.to_string()
    }
  end

#logica de compra
  def comprar_completo(jugador_id, sorteo_id, numero_billete, precio_billete, estado_sorteo, billetes) do
    with :ok <- validar_sorteo_pendiente(estado_sorteo),
        {:ok, billete} <- buscar_billete(billetes, numero_billete),
        :ok <- validar_billete_completo_disponible(billete) do

      case Billete.comprar_fracciones(billete, jugador_id, billete.fracciones_disponibles, precio_billete / billete.fracciones_disponibles) do
        {:ok, billete_actualizado} ->
          apuesta = nueva(jugador_id, sorteo_id, numero_billete, billete_actualizado.fracciones_vendidas, precio_billete)
          {:ok, apuesta, billete_actualizado}

        {:error, motivo} ->
          {:error, motivo}
      end
    end
  end


  def comprar_fracciones(jugador_id, sorteo_id, numero_billete, cantidad_fracciones, precio_fraccion, estado_sorteo, billetes) do
    with :ok <- validar_sorteo_pendiente(estado_sorteo),
        {:ok, billete} <- buscar_billete(billetes, numero_billete),
        :ok <- validar_fracciones_disponibles(billete, cantidad_fracciones) do

      case Billete.comprar_fracciones(billete, jugador_id, cantidad_fracciones, precio_fraccion) do
        {:ok, billete_actualizado} ->
          monto = precio_fraccion * cantidad_fracciones
          apuesta = nueva(jugador_id, sorteo_id, numero_billete, cantidad_fracciones, monto)
          {:ok, apuesta, billete_actualizado}

        {:error, motivo} ->
          {:error, motivo}
      end
    end
  end


  def devolver(%__MODULE__{} = apuesta, estado_sorteo, billetes) do
    with :ok <- validar_sorteo_pendiente(estado_sorteo),
        {:ok, billete} <- buscar_billete(billetes, apuesta.numero_billete) do
      Billete.devolver_fracciones(billete, apuesta.jugador_id, apuesta.fracciones)
    end
  end


#Retorna todas las apuestas de un jugador específico.

  def historial_por_jugador(apuestas, jugador_id) do
    apuestas
    |> Enum.filter(fn a -> a.jugador_id == jugador_id end)
  end


  #Calcula el total gastado por un jugador en todas sus apuestas.

  def total_gastado(apuestas, jugador_id) do
    apuestas
    |> historial_por_jugador(jugador_id)
    |> Enum.reduce(0.0, fn a, acc -> acc + a.monto end)
  end

  @doc """
  Verifica si un jugador ganó en un sorteo dado los números ganadores.

  Retorna lista de apuestas ganadoras (puede ser vacía).
  """
  def verificar_premios(apuestas, jugador_id, sorteo_id, numeros_ganadores) do
    apuestas
    |> historial_por_jugador(jugador_id)
    |> Enum.filter(fn a ->
      a.sorteo_id == sorteo_id and a.numero_billete in numeros_ganadores
    end)
  end

  @doc """
  Retorna todas las apuestas de un sorteo específico.
  """
  def por_sorteo(apuestas, sorteo_id) do
    apuestas
    |> Enum.filter(fn a -> a.sorteo_id == sorteo_id end)
  end

  @doc """
  Calcula los ingresos totales de un sorteo.
  """
  def ingresos_sorteo(apuestas, sorteo_id) do
    apuestas
    |> por_sorteo(sorteo_id)
    |> Enum.reduce(0.0, fn a, acc -> acc + a.monto end)
  end


  @doc """
  Guarda la lista de apuestas en apuestas.json
  """
  def guardar_json(apuestas, nombre_archivo \\ "apuestas.json") do
    apuestas
    |> Jason.encode!()
    |> (&File.write!(nombre_archivo, &1)).()
  end

  @doc """
  Carga las apuestas desde apuestas.json
  Retorna lista vacía si el archivo no existe.
  """
  def cargar_json(nombre_archivo \\ "apuestas.json") do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        contenido
        |> Jason.decode!()
        |> Enum.map(&desde_mapa/1)

      {:error, :enoent} ->
        []
    end
  end


  @doc """
  Muestra en pantalla la información de una apuesta.
  """
  def mostrar(%__MODULE__{} = apuesta) do
    "Apuesta #{apuesta.id} | Jugador: #{apuesta.jugador_id} | " <>
    "Sorteo: #{apuesta.sorteo_id} | Billete ##{apuesta.numero_billete} | " <>
    "Fracciones: #{apuesta.fracciones} | Monto: $#{apuesta.monto} | #{apuesta.fecha}"
    |> Util.mostrar_mensaje()
  end

#validaciones

  defp validar_sorteo_pendiente(:pendiente), do: :ok
  defp validar_sorteo_pendiente(:realizado), do: {:error, "El sorteo ya fue realizado"}
  defp validar_sorteo_pendiente(:cancelado), do: {:error, "El sorteo está cancelado"}

  defp buscar_billete(billetes, numero_billete) do
    case Enum.find(billetes, fn b -> b.numero == numero_billete end) do
      nil     -> {:error, "El billete ##{numero_billete} no existe en este sorteo"}
      billete -> {:ok, billete}
    end
  end

  defp validar_billete_completo_disponible(billete) do
    case Billete.disponible_completo?(billete) do
      true  -> :ok
      false -> {:error, "El billete ##{billete.numero} ya tiene fracciones vendidas"}
    end
  end

  defp validar_fracciones_disponibles(billete, cantidad) do
    case Billete.fracciones_disponibles?(billete, cantidad) do
      true  -> :ok
      false -> {:error, "Solo hay #{billete.fracciones_disponibles} fracciones disponibles en el billete ##{billete.numero}"}
    end
  end

  
  defp desde_mapa(mapa) do
    %__MODULE__{
      id: mapa["id"],
      jugador_id: mapa["jugador_id"],
      sorteo_id: mapa["sorteo_id"],
      numero_billete: mapa["numero_billete"],
      fracciones: mapa["fracciones"],
      monto: mapa["monto"],
      fecha: mapa["fecha"]
    }
  end

  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> (&"APU-#{&1}").()
  end
end
