defmodule Azar.Billete do

  @derive {Jason.Encoder, only: [
    :numero,
    :sorteo_id,
    :fracciones_disponibles,
    :fracciones_vendidas,
    :compradores
  ]}
  defstruct [
    numero: nil,               # Número único del billete dentro del sorteo
    sorteo_id: nil,            # ID del sorteo al que pertenece
    fracciones_disponibles: 0, # Cuántas fracciones quedan por vender
    fracciones_vendidas: 0,    # Cuántas fracciones ya fueron vendidas
    compradores: []            # Lista de mapas %{jugador_id, fracciones, monto}
  ]

  alias Azar.Util

  @doc """
  Crea un billete nuevo con todas sus fracciones disponibles.
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
  Verifica si el billete completo está disponible (ninguna fracción vendida).
  """
  def disponible_completo?(%__MODULE__{fracciones_vendidas: vendidas}), do: vendidas == 0

  @doc """
  Verifica si hay al menos `cantidad` fracciones disponibles.
  """
  def fracciones_disponibles?(%__MODULE__{fracciones_disponibles: disp}, cantidad),
    do: disp >= cantidad

  @doc """
  Retorna cuántas fracciones compró un jugador en este billete.
  """
  def fracciones_de_jugador(%__MODULE__{compradores: compradores}, jugador_id) do
    compradores
    |> Enum.filter(fn c -> c.jugador_id == jugador_id end)
    |> Enum.reduce(0, fn c, acc -> acc + c.fracciones end)
  end

  @doc """
  Registra la compra de `cantidad` fracciones para un jugador.
  """
  def comprar_fracciones(%__MODULE__{} = billete, jugador_id, cantidad, precio_fraccion) do
    cond do
      not fracciones_disponibles?(billete, cantidad) ->
        {:error, "No hay suficientes fracciones disponibles"}

      cantidad <= 0 ->
        {:error, "La cantidad debe ser mayor a cero"}

      true ->
        monto = precio_fraccion * cantidad

        nuevo_comprador = %{
          jugador_id: jugador_id,
          fracciones: cantidad,
          monto: monto
        }

        billete_actualizado = %{billete |
          fracciones_disponibles: billete.fracciones_disponibles - cantidad,
          fracciones_vendidas: billete.fracciones_vendidas + cantidad,
          compradores: billete.compradores ++ [nuevo_comprador]
        }

        {:ok, billete_actualizado}
    end
  end

  @doc """
  Registra la devolución de fracciones de un jugador.
  """
  def devolver_fracciones(%__MODULE__{} = billete, jugador_id, cantidad) do
    fracciones_del_jugador = fracciones_de_jugador(billete, jugador_id)

    cond do
      fracciones_del_jugador < cantidad ->
        {:error, "El jugador no tiene tantas fracciones para devolver"}

      true ->
        # Reducimos del último registro del jugador primero
        compradores_actualizados =
          billete.compradores
          |> quitar_fracciones(jugador_id, cantidad, [])

        billete_actualizado = %{billete |
          fracciones_disponibles: billete.fracciones_disponibles + cantidad,
          fracciones_vendidas: billete.fracciones_vendidas - cantidad,
          compradores: compradores_actualizados
        }

        {:ok, billete_actualizado}
    end
  end


  @doc """
  Guarda la lista de billetes de un sorteo en su archivo JSON.
  El archivo se almacena en billetes/<sorteo_id>.json
  """
  def guardar_json(billetes, sorteo_id) do
    File.mkdir_p!("billetes")
    path = "billetes/#{sorteo_id}.json"

    billetes
    |> Jason.encode!()
    |> (&File.write!(path, &1)).()
  end

  @doc """
  Carga los billetes de un sorteo desde su archivo JSON.
  Retorna lista vacía si el archivo no existe.
  """
  def cargar_json(sorteo_id) do
    path = "billetes/#{sorteo_id}.json"

    case File.read(path) do
      {:ok, contenido} ->
        contenido
        |> Jason.decode!()
        |> Enum.map(&desde_mapa/1)

      {:error, :enoent} ->
        []
    end
  end

  @doc """
  Genera todos los billetes para un sorteo dado su cantidad y fracciones.
  Los números van del 1 al `cantidad_billetes`.
  """
  def generar_para_sorteo(sorteo_id, cantidad_billetes, fracciones_totales) do
    1..cantidad_billetes
    |> Enum.map(fn numero ->
      nuevo(numero, sorteo_id, fracciones_totales)
    end)
  end


  defp desde_mapa(mapa) do
    compradores =
      mapa["compradores"]
      |> Enum.map(fn c ->
        %{
          jugador_id: c["jugador_id"],
          fracciones: c["fracciones"],
          monto: c["monto"]
        }
      end)

    %__MODULE__{
      numero: mapa["numero"],
      sorteo_id: mapa["sorteo_id"],
      fracciones_disponibles: mapa["fracciones_disponibles"],
      fracciones_vendidas: mapa["fracciones_vendidas"],
      compradores: compradores
    }
  end

  # Quita `cantidad` fracciones de los registros del jugador (de atrás hacia adelante)
  defp quitar_fracciones([], _jugador_id, _restante, acum), do: Enum.reverse(acum)

  defp quitar_fracciones([comprador | resto], jugador_id, 0, acum),
    do: quitar_fracciones(resto, jugador_id, 0, [comprador | acum])

  defp quitar_fracciones([comprador | resto], jugador_id, restante, acum)
      when comprador.jugador_id == jugador_id do
    cond do
      comprador.fracciones <= restante ->
        # Eliminar este registro completo
        quitar_fracciones(resto, jugador_id, restante - comprador.fracciones, acum)

      true ->
        # Reducir parcialmente este registro
        actualizado = %{comprador | fracciones: comprador.fracciones - restante}
        quitar_fracciones(resto, jugador_id, 0, [actualizado | acum])
    end
  end

  defp quitar_fracciones([comprador | resto], jugador_id, restante, acum),
    do: quitar_fracciones(resto, jugador_id, restante, [comprador | acum])

  @doc """
  Muestra en pantalla la información de un billete.
  """
  def mostrar(%__MODULE__{} = billete) do
    "Billete ##{billete.numero} | Sorteo: #{billete.sorteo_id} | " <>
    "Fracciones disponibles: #{billete.fracciones_disponibles} / " <>
    "vendidas: #{billete.fracciones_vendidas}"
    |> Util.mostrar_mensaje()
  end
end
