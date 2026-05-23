defmodule Azar.SorteoServer do
  @moduledoc """
  GenServer que centraliza la gestión de sorteos.
  Maneja CRUD completo, persistencia JSON, filtrado y cierre con ganadores.
  """
  use GenServer
  alias Azar.Sorteo
  alias Azar.Logger

  @storage_dir "sorteos"

  # ════════════════════════════════════════════
  # API Pública
  # ════════════════════════════════════════════

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Crea un nuevo sorteo con los atributos dados."
  def crear_sorteo(attrs) do
    GenServer.call(__MODULE__, {:crear, attrs})
  end

  @doc "Lista todos los sorteos."
  def listar_sorteos do
    GenServer.call(__MODULE__, :listar)
  end

  @doc "Filtra sorteos por estado (:pendiente, :realizado, :cancelado) o por fecha."
  def filtrar_sorteos(filtro) do
    GenServer.call(__MODULE__, {:filtrar, filtro})
  end

  @doc "Consulta el detalle de un sorteo específico por ID."
  def consultar_sorteo(id) do
    GenServer.call(__MODULE__, {:consultar, id})
  end

  @doc "Cierra un sorteo: genera ganadores y cambia estado a :realizado."
  def cerrar_sorteo(id) do
    GenServer.call(__MODULE__, {:cerrar, id})
  end

  @doc "Cancela un sorteo: cambia estado a :cancelado."
  def cancelar_sorteo(id) do
    GenServer.call(__MODULE__, {:cancelar, id})
  end

  @doc "Compra fracciones de un billete en un sorteo."
  def comprar_fraccion(sorteo_id, numero_billete, jugador_id, cantidad_fracciones) do
    GenServer.call(__MODULE__, {:comprar, sorteo_id, numero_billete, jugador_id, cantidad_fracciones})
  end

  @doc "Obtiene un sorteo directamente (sin GenServer, para uso interno)."
  def obtener_sorteo(id) do
    GenServer.call(__MODULE__, {:consultar, id})
  end

  # ════════════════════════════════════════════
  # Callbacks GenServer
  # ════════════════════════════════════════════

  @impl true
  def init(_) do
    File.mkdir_p!(@storage_dir)
    sorteos_cargados = cargar_desde_disco()
    {:ok, sorteos_cargados}
  end

  # --- Crear sorteo ---
  @impl true
  def handle_call({:crear, attrs}, _from, estado) do
    nuevo_sorteo = Sorteo.nueva_instancia(attrs)
    guardar_en_disco(nuevo_sorteo)
    nuevo_estado = Map.put(estado, nuevo_sorteo.id, nuevo_sorteo)
    Logger.registrar("Crear sorteo", "Sorteo '#{nuevo_sorteo.nombre}' creado con ID #{nuevo_sorteo.id}")
    {:reply, {:ok, nuevo_sorteo}, nuevo_estado}
  end

  # --- Listar todos ---
  @impl true
  def handle_call(:listar, _from, estado) do
    lista = Map.values(estado)
    {:reply, lista, estado}
  end

  # --- Filtrar sorteos ---
  @impl true
  def handle_call({:filtrar, {:estado, estado_filtro}}, _from, estado) do
    estado_str = to_string(estado_filtro)

    filtrados =
      estado
      |> Map.values()
      |> Enum.filter(fn s -> to_string(s.estado) == estado_str end)

    {:reply, filtrados, estado}
  end

  @impl true
  def handle_call({:filtrar, {:fecha, fecha}}, _from, estado) do
    filtrados =
      estado
      |> Map.values()
      |> Enum.filter(fn s -> s.fecha == fecha end)

    {:reply, filtrados, estado}
  end

  # --- Consultar sorteo ---
  @impl true
  def handle_call({:consultar, id}, _from, estado) do
    id_int = normalizar_id(id)

    case Map.get(estado, id_int) do
      nil -> {:reply, {:error, "Sorteo no encontrado con ID #{id}"}, estado}
      sorteo -> {:reply, {:ok, sorteo}, estado}
    end
  end

  # --- Cerrar sorteo (generar ganadores) ---
  @impl true
  def handle_call({:cerrar, id}, _from, estado) do
    id_int = normalizar_id(id)

    case Map.get(estado, id_int) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      %{estado: :realizado} ->
        {:reply, {:error, "El sorteo ya fue realizado"}, estado}

      %{estado: :cancelado} ->
        {:reply, {:error, "El sorteo está cancelado"}, estado}

      sorteo ->
        sorteo_finalizado = Sorteo.seleccionar_ganadores(sorteo)
        guardar_en_disco(sorteo_finalizado)
        nuevo_estado = Map.put(estado, id_int, sorteo_finalizado)
        Logger.registrar("Cerrar sorteo", "Sorteo '#{sorteo.nombre}' cerrado con ganadores")
        {:reply, {:ok, sorteo_finalizado}, nuevo_estado}
    end
  end

  # --- Cancelar sorteo ---
  @impl true
  def handle_call({:cancelar, id}, _from, estado) do
    id_int = normalizar_id(id)

    case Map.get(estado, id_int) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      %{estado: :realizado} ->
        {:reply, {:error, "No se puede cancelar un sorteo ya realizado"}, estado}

      sorteo ->
        sorteo_cancelado = %{sorteo | estado: :cancelado}
        guardar_en_disco(sorteo_cancelado)
        nuevo_estado = Map.put(estado, id_int, sorteo_cancelado)
        Logger.registrar("Cancelar sorteo", "Sorteo '#{sorteo.nombre}' cancelado")
        {:reply, {:ok, sorteo_cancelado}, nuevo_estado}
    end
  end

  # --- Comprar fracción (atómico para concurrencia) ---
  @impl true
  def handle_call({:comprar, sorteo_id, numero_billete, jugador_id, cantidad}, _from, estado) do
    sorteo_id_int = normalizar_id(sorteo_id)

    case Map.get(estado, sorteo_id_int) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      %{estado: est} when est != :pendiente ->
        {:reply, {:error, "El sorteo no está abierto para compras (estado: #{est})"}, estado}

      sorteo ->
        billete_key = String.pad_leading(to_string(numero_billete), 3, "0")

        case Map.get(sorteo.billetes, billete_key) do
          nil ->
            {:reply, {:error, "Billete #{billete_key} no encontrado"}, estado}

          billete ->
            disponibles = Map.get(billete, :fracciones_disponibles, 0)

            if cantidad > disponibles do
              {:reply, {:error, "Solo hay #{disponibles} fracciones disponibles"}, estado}
            else
              # Actualizar billete
              vendidas_actual = Map.get(billete, :fracciones_vendidas, 0)
              compradores_actual = Map.get(billete, :compradores, [])

              billete_actualizado =
                billete
                |> Map.put(:fracciones_disponibles, disponibles - cantidad)
                |> Map.put(:fracciones_vendidas, vendidas_actual + cantidad)
                |> Map.put(:compradores, compradores_actual ++ [%{jugador_id: jugador_id, fracciones: cantidad}])

              # Calcular monto
              precio_fraccion = Sorteo.precio_fraccion(sorteo)
              monto = precio_fraccion * cantidad

              # Actualizar sorteo
              nuevos_billetes = Map.put(sorteo.billetes, billete_key, billete_actualizado)

              sorteo_actualizado = %{
                sorteo
                | billetes: nuevos_billetes,
                  ingresos_totales: sorteo.ingresos_totales + monto
              }

              guardar_en_disco(sorteo_actualizado)
              nuevo_estado = Map.put(estado, sorteo_id_int, sorteo_actualizado)

              Logger.registrar(
                "Compra de fracción",
                "Jugador #{jugador_id} compró #{cantidad} fracción(es) del billete #{billete_key} en sorteo #{sorteo_id_int}"
              )

              {:reply, {:ok, %{monto: monto, billete: billete_key, fracciones: cantidad}}, nuevo_estado}
            end
        end
    end
  end

  # ════════════════════════════════════════════
  # Persistencia
  # ════════════════════════════════════════════

  defp guardar_en_disco(sorteo) do
    path = Path.join(@storage_dir, "sorteo_#{sorteo.id}.json")
    contenido = Jason.encode!(sorteo, pretty: true)
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

        # Convertir estado string a átomo si viene de JSON
        datos =
          Map.update(datos, :estado, :pendiente, fn
            e when is_binary(e) -> String.to_atom(e)
            e -> e
          end)

        struct(Sorteo, datos)
      end)
      |> Enum.into(%{}, fn s -> {s.id, s} end)
    else
      %{}
    end
  end

  defp normalizar_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> n
      :error -> id
    end
  end

  defp normalizar_id(id), do: id
end
