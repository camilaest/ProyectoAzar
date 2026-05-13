defmodule Azar.SorteoServer do
  @moduledoc """
  GenServer que centraliza todas las operaciones de sorteos.

  Al usar GenServer como punto de serialización, todos los mensajes
  se procesan uno a uno (FIFO), lo que garantiza que dos jugadores
  no puedan comprar la misma fracción simultáneamente (sin necesidad
  de semáforos ni memoria compartida — modelo de actores de Elixir).

  - fecha: Mayo del 2026
  - Licencia: GNU GPL v3
  """

  use GenServer
  alias Azar.{Sorteo, Billete, Apuesta, Logger}

  @storage_dir "sorteos"

  # ===========================================================================
  # API Pública
  # ===========================================================================

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Crea un nuevo sorteo y lo persiste en disco."
  def crear_sorteo(attrs) do
    GenServer.call(__MODULE__, {:crear, attrs})
  end

  @doc "Devuelve la lista de todos los sorteos cargados en memoria."
  def listar_sorteos do
    GenServer.call(__MODULE__, :listar)
  end

  @doc "Devuelve solo sorteos en estado :pendiente (disponibles para apostar)."
  def sorteos_disponibles do
    GenServer.call(__MODULE__, :disponibles)
  end

  @doc "Consulta el detalle de un sorteo específico por ID."
  def consultar_sorteo(id) do
    GenServer.call(__MODULE__, {:consultar, id})
  end

  @doc """
  Intenta comprar fracciones de un billete de manera atómica.

  Al ser un GenServer, los mensajes se procesan en orden FIFO.
  Esto garantiza que si dos jugadores intentan comprar la misma fracción
  al mismo tiempo, solo uno tendrá éxito — el otro recibirá {:error, ...}.

  ## Parámetros
    - sorteo_id: ID del sorteo
    - numero_billete: número del billete (ej: "005")
    - jugador_id: identificación del jugador comprador
    - cantidad_fracciones: cuántas fracciones quiere comprar (default 1)

  ## Retorna
    - {:ok, apuesta} si la compra fue exitosa
    - {:error, razon} si no fue posible (sorteo cerrado, sin fracciones, etc.)
  """
  def comprar_fraccion(sorteo_id, numero_billete, jugador_id, cantidad_fracciones \\ 1) do
    GenServer.call(__MODULE__, {:comprar, sorteo_id, numero_billete, jugador_id, cantidad_fracciones})
  end

  @doc "Devuelve una apuesta (si el sorteo aún no se realizó)."
  def devolver_apuesta(sorteo_id, apuesta_id) do
    GenServer.call(__MODULE__, {:devolver, sorteo_id, apuesta_id})
  end

  @doc "Finaliza un sorteo: selecciona ganadores y cambia estado a :realizado."
  def finalizar_sorteo(id) do
    GenServer.call(__MODULE__, {:finalizar, id})
  end

  @doc "Elimina un sorteo (solo si no tiene compradores)."
  def eliminar_sorteo(id) do
    GenServer.call(__MODULE__, {:eliminar, id})
  end

  @doc "Devuelve los ingresos totales de un sorteo dado."
  def ingresos_sorteo(id) do
    GenServer.call(__MODULE__, {:ingresos, id})
  end

  # ===========================================================================
  # Callbacks del GenServer
  # ===========================================================================

  @impl true
  def init(_) do
    File.mkdir_p!(@storage_dir)
    sorteos = cargar_desde_disco()
    {:ok, sorteos}
  end

  # --- Crear sorteo ---
  @impl true
  def handle_call({:crear, attrs}, _from, estado) do
    nuevo = Sorteo.nueva_instancia(attrs)
    guardar_en_disco(nuevo)
    nuevo_estado = Map.put(estado, nuevo.id, nuevo)
    Logger.registrar("Crear sorteo", "OK - ID: #{nuevo.id}")
    {:reply, {:ok, nuevo}, nuevo_estado}
  end

  # --- Listar todos ---
  @impl true
  def handle_call(:listar, _from, estado) do
    lista = estado |> Map.values() |> Enum.sort_by(& &1.fecha)
    {:reply, lista, estado}
  end

  # --- Sorteos disponibles (pendientes) ---
  @impl true
  def handle_call(:disponibles, _from, estado) do
    disponibles =
      estado
      |> Map.values()
      |> Enum.filter(fn s -> s.estado == :pendiente end)
      |> Enum.sort_by(& &1.fecha)
    {:reply, disponibles, estado}
  end

  # --- Consultar sorteo por ID ---
  @impl true
  def handle_call({:consultar, id}, _from, estado) do
    case Map.get(estado, normalizar_id(id, estado)) do
      nil -> {:reply, {:error, "Sorteo no encontrado"}, estado}
      sorteo -> {:reply, {:ok, sorteo}, estado}
    end
  end

  # --- Compra atómica de fracción ---
  # Este es el corazón de la concurrencia: al ser handle_call,
  # Elixir garantiza que solo un proceso a la vez ejecuta este bloque.
  @impl true
  def handle_call({:comprar, sorteo_id, numero_billete, jugador_id, cantidad}, _from, estado) do
    id = normalizar_id(sorteo_id, estado)

    with {:sorteo, sorteo} when not is_nil(sorteo) <- {:sorteo, Map.get(estado, id)},
        {:pendiente, true} <- {:pendiente, sorteo.estado == :pendiente},
        {:billete, billete} when not is_nil(billete) <- {:billete, obtener_billete(sorteo, numero_billete)},
        monto = calcular_monto(sorteo, cantidad),
        {:compra, {:ok, billete_actualizado}} <- {:compra, Billete.registrar_compra(billete, jugador_id, cantidad, monto)} do

      # Crear la apuesta
      apuesta = Apuesta.nueva(%{
        jugador_id: jugador_id,
        sorteo_id: id,
        numero_billete: numero_billete,
        fracciones: cantidad,
        monto: monto * cantidad
      })

      # Persistir la apuesta en su JSON
      apuestas_actuales = Apuesta.cargar_apuestas()
      Apuesta.guardar_apuestas(apuestas_actuales ++ [apuesta])

      # Actualizar el billete dentro del sorteo
      sorteo_actualizado = actualizar_billete_en_sorteo(sorteo, billete_actualizado)
      guardar_en_disco(sorteo_actualizado)
      nuevo_estado = Map.put(estado, id, sorteo_actualizado)

      Logger.registrar(
        "Compra fracción - Jugador: #{jugador_id} - Sorteo: #{id} - Billete: #{numero_billete}",
        "OK - Apuesta ID: #{apuesta.id}"
      )

      {:reply, {:ok, apuesta}, nuevo_estado}
    else
      {:sorteo, nil}    -> {:reply, {:error, "Sorteo no encontrado"}, estado}
      {:pendiente, _}   -> {:reply, {:error, "El sorteo ya no está disponible para apuestas"}, estado}
      {:billete, nil}   -> {:reply, {:error, "Número de billete no válido para este sorteo"}, estado}
      {:compra, error}  -> {:reply, error, estado}
    end
  end

  # --- Devolución de apuesta ---
  @impl true
  def handle_call({:devolver, sorteo_id, apuesta_id}, _from, estado) do
    id = normalizar_id(sorteo_id, estado)

    with {:sorteo, sorteo} when not is_nil(sorteo) <- {:sorteo, Map.get(estado, id)},
         {:pendiente, true} <- {:pendiente, sorteo.estado == :pendiente},
         {:devolucion, {:ok, apuesta}} <- {:devolucion, Apuesta.devolver(apuesta_id)} do

      # Liberar la fracción en el billete del sorteo
      sorteo_actualizado = liberar_fraccion_en_sorteo(sorteo, apuesta.numero_billete, apuesta.fracciones)
      guardar_en_disco(sorteo_actualizado)
      nuevo_estado = Map.put(estado, id, sorteo_actualizado)

      Logger.registrar("Devolución apuesta #{apuesta_id}", "OK")
      {:reply, {:ok, apuesta}, nuevo_estado}
    else
      {:sorteo, nil}    -> {:reply, {:error, "Sorteo no encontrado"}, estado}
      {:pendiente, _}   -> {:reply, {:error, "No se puede devolver: el sorteo ya se realizó"}, estado}
      {:devolucion, err} -> {:reply, err, estado}
    end
  end

  # --- Finalizar sorteo ---
  @impl true
  def handle_call({:finalizar, id_raw}, _from, estado) do
    id = normalizar_id(id_raw, estado)

    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      sorteo ->
        finalizado = Sorteo.seleccionar_ganadores(sorteo)
        guardar_en_disco(finalizado)
        nuevo_estado = Map.put(estado, id, finalizado)
        Logger.registrar("Finalizar sorteo #{id}", "OK - Ganadores asignados")
        {:reply, {:ok, finalizado}, nuevo_estado}
    end
  end

  # --- Eliminar sorteo ---
  @impl true
  def handle_call({:eliminar, id_raw}, _from, estado) do
    id = normalizar_id(id_raw, estado)

    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      sorteo ->
        if tiene_compradores?(sorteo) do
          {:reply, {:error, "No se puede eliminar: el sorteo tiene compradores"}, estado}
        else
          archivo = Path.join(@storage_dir, "sorteo_#{id}.json")
          File.rm(archivo)
          nuevo_estado = Map.delete(estado, id)
          Logger.registrar("Eliminar sorteo #{id}", "OK")
          {:reply, :ok, nuevo_estado}
        end
    end
  end

  # --- Ingresos de un sorteo ---
  @impl true
  def handle_call({:ingresos, id_raw}, _from, estado) do
    id = normalizar_id(id_raw, estado)

    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      sorteo ->
        total = calcular_ingresos(sorteo)
        {:reply, {:ok, total}, estado}
    end
  end

  # ===========================================================================
  # Funciones privadas — Lógica interna
  # ===========================================================================

  # Obtiene un billete del sorteo por su número.
  # Los billetes pueden estar como mapa (cargado de JSON) o struct.
  defp obtener_billete(sorteo, numero) do
    case sorteo.billetes do
      billetes when is_map(billetes) ->
        raw = Map.get(billetes, numero) || Map.get(billetes, String.to_atom(numero))
        case raw do
          nil -> nil
          %Billete{} = b -> b
          mapa -> Billete.desde_mapa(mapa)
        end
      _ -> nil
    end
  end

  # Actualiza el billete modificado dentro del mapa de billetes del sorteo.
  defp actualizar_billete_en_sorteo(sorteo, billete_actualizado) do
    billetes_nuevos = Map.put(sorteo.billetes, billete_actualizado.numero, billete_actualizado)
    %{sorteo | billetes: billetes_nuevos}
  end

  # Libera fracciones de un billete cuando se devuelve una apuesta.
  defp liberar_fraccion_en_sorteo(sorteo, numero_billete, cantidad) do
    case obtener_billete(sorteo, numero_billete) do
      nil -> sorteo
      billete ->
        liberado = %{billete |
          fracciones_disponibles: billete.fracciones_disponibles + cantidad,
          fracciones_vendidas: billete.fracciones_vendidas - cantidad
        }
        actualizar_billete_en_sorteo(sorteo, liberado)
    end
  end

  # Calcula el monto por fracción según el precio del billete y fracciones totales.
  defp calcular_monto(sorteo, _cantidad) do
    fracciones = if sorteo.fracciones_totales > 0, do: sorteo.fracciones_totales, else: 1
    div(sorteo.precio_billete, fracciones)
  end

  # Verifica si un sorteo ya tiene algún comprador registrado.
  defp tiene_compradores?(sorteo) do
    sorteo.billetes
    |> Map.values()
    |> Enum.any?(fn b ->
      billete = if is_map(b) and not is_struct(b), do: Billete.desde_mapa(b), else: b
      billete.fracciones_vendidas > 0
    end)
  end

  # Suma todos los ingresos del sorteo revisando compradores en cada billete.
  defp calcular_ingresos(sorteo) do
    sorteo.billetes
    |> Map.values()
    |> Enum.flat_map(fn b ->
      billete = if is_map(b) and not is_struct(b), do: Billete.desde_mapa(b), else: b
      billete.compradores
    end)
    |> Enum.reduce(0, fn c, acc -> acc + Map.get(c, :monto, 0) end)
  end

  # Normaliza el ID: acepta entero, string, o átomo y lo busca en el estado.
  defp normalizar_id(id, estado) when is_binary(id) do
    caso_entero = String.to_integer(id)
    if Map.has_key?(estado, caso_entero), do: caso_entero, else: id
  rescue
    _ -> id
  end
  defp normalizar_id(id, _estado), do: id

  # ===========================================================================
  # Funciones privadas — Persistencia
  # ===========================================================================

  defp guardar_en_disco(sorteo) do
    path = Path.join(@storage_dir, "sorteo_#{sorteo.id}.json")
    contenido = Jason.encode!(sorteo)
    File.write!(path, contenido)
  end

  defp cargar_desde_disco do
    if File.exists?(@storage_dir) do
      @storage_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".json"))
      |> Enum.map(fn archivo ->
        path = Path.join(@storage_dir, archivo)
        datos = path |> File.read!() |> Jason.decode!(keys: :atoms)
        struct(Sorteo, reconstruir_billetes(datos))
      end)
      |> Enum.into(%{}, fn s -> {s.id, s} end)
    else
      %{}
    end
  end

  # Reconstruye el mapa de billetes como structs %Billete{} al cargar desde JSON.
  defp reconstruir_billetes(%{billetes: nil} = datos), do: datos
  defp reconstruir_billetes(%{billetes: billetes_raw} = datos) when is_map(billetes_raw) do
    billetes =
      billetes_raw
      |> Enum.map(fn {k, v} ->
        numero = to_string(k)
        billete = Billete.desde_mapa(v)
        {numero, %{billete | numero: numero}}
      end)
      |> Enum.into(%{})

    %{datos | billetes: billetes}
  end
  defp reconstruir_billetes(datos), do: datos
end
