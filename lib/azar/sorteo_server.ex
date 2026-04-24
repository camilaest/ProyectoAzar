defmodule Azar.SorteoServer do
  use GenServer
  alias Azar.Sorteo
  alias Azar.Logger

  # --- Interfaz (Lo que llaman los clientes) ---

  def start_link(%Azar.Sorteo{} = datos) do
    # Iniciamos el proceso dándole un nombre único basado en su ID [cite: 18]
    GenServer.start_link(__MODULE__, datos, name: {:global, datos.id})
  end

  def obtener_info(id_sorteo) do
    GenServer.call({:global, id_sorteo}, :consultar)
  end

  # --- Servidor (Callbacks del GenServer) ---

  @impl true
  def init(%Sorteo{} = sorteo) do
    # Al arrancar, verificamos si ya existe un archivo JSON para este sorteo [cite: 19]
    path = "sorteos/#{sorteo.id}.json"

    estado_actual = case File.read(path) do
      {:ok, contenido} ->
        # Si existe, cargamos los datos del archivo
        Jason.decode!(contenido, keys: :atoms)
      {:error, _} ->
        # Si no existe, usamos los datos nuevos y creamos el archivo
        guardar_json(sorteo)
        sorteo
    end

    {:ok, estado_actual}
  end

  @impl true
  def handle_call(:consultar, _from, estado) do
    Logger.registrar("Consulta de datos sorteo: #{estado.nombre}", "ok") [cite: 22]
    {:reply, estado, estado}
  end

  # Función privada para persistir datos en JSON [cite: 19, 112]
  defp guardar_json(estado) do
    File.mkdir_p!("sorteos")
    path = "sorteos/#{estado.id}.json"
    File.write!(path, Jason.encode!(estado))
  end
end
