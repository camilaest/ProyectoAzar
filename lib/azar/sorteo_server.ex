defmodule Azar.SorteoServer do
  use GenServer
  alias Azar.Sorteo

  @storage_dir "sorteos"

  # --- API Pública ---

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def crear_sorteo(attrs) do
    GenServer.call(__MODULE__, {:crear, attrs})
  end

  def listar_sorteos do
    GenServer.call(__MODULE__, :listar)
  end

  def finalizar_sorteo(id) do
    GenServer.call(__MODULE__, {:finalizar, id})
  end

  @impl true
  def init(_) do
    File.mkdir_p!(@storage_dir)
    sorteos_cargados = cargar_desde_disco()
    {:ok, sorteos_cargados}
  end

  @impl true
  def handle_call({:crear, attrs}, _from, estado) do
    nuevo_sorteo = Sorteo.nueva_instancia(attrs)
    guardar_en_disco(nuevo_sorteo)
    nuevo_estado = Map.put(estado, nuevo_sorteo.id, nuevo_sorteo)
    {:reply, {:ok, nuevo_sorteo}, nuevo_estado}
  end

  @impl true
  def handle_call(:listar, _from, estado) do
    lista = Map.values(estado)
    {:reply, lista, estado}
  end

  @impl true
  def handle_call({:finalizar, id}, _from, estado) do
    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "Sorteo no encontrado"}, estado}

      sorteo ->
        sorteo_finalizado = Sorteo.seleccionar_ganadores(sorteo)
        guardar_en_disco(sorteo_finalizado)
        nuevo_estado = Map.put(estado, id, sorteo_finalizado)
        {:reply, {:ok, sorteo_finalizado}, nuevo_estado}
    end
  end

  # --- Persistencia ---

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
        # Cargamos el JSON y convertimos llaves a átomos para el struct
        datos = path |> File.read!() |> Jason.decode!(keys: :atoms)
        struct(Sorteo, datos)
      end)
      |> Enum.into(%{}, fn s -> {s.id, s} end)
    else
      %{}
    end
  end
end
