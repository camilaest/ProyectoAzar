defmodule Azar.Servidor do
  @moduledoc """
  Módulo para el nodo servidor distribuido de Azar S.A.
  Arranca todos los GenServers necesarios y los registra globalmente.
  """

  alias Azar.Logger

  @doc """
  Inicia el servidor con todos los GenServers necesarios.
  Registra los procesos globalmente para acceso desde nodos remotos.
  """
  def iniciar do
    IO.puts("""

    ╔══════════════════════════════════════════╗
    ║      AZAR S.A. - SERVIDOR CENTRAL       ║
    ║      Iniciando servicios...              ║
    ╚══════════════════════════════════════════╝
    """)

    # Iniciar GenServers
    {:ok, sorteo_pid} = Azar.SorteoServer.start_link([])
    {:ok, notificador_pid} = Azar.Notificador.start_link([])

    # Registrar globalmente para acceso distribuido
    :global.register_name(:sorteo_server, sorteo_pid)
    :global.register_name(:notificador, notificador_pid)

    Logger.registrar("Servidor", "Todos los servicios iniciados correctamente")

    IO.puts("  ✅ SorteoServer iniciado (PID: #{inspect(sorteo_pid)})")
    IO.puts("  ✅ Notificador iniciado (PID: #{inspect(notificador_pid)})")
    IO.puts("  ✅ Nodo: #{Node.self()}")
    IO.puts("\n  Servidor listo para recibir conexiones.\n")

    :ok
  end

  @doc """
  Inicia el nodo como servidor distribuido con un nombre dado.
  Uso: Azar.Servidor.iniciar_nodo("servidor")
  """
  def iniciar_nodo(nombre \\ "servidor") do
    hostname = obtener_hostname()
    nombre_nodo = :"#{nombre}@#{hostname}"

    case Node.start(nombre_nodo) do
      {:ok, _} ->
        Node.set_cookie(:azar_cookie)
        IO.puts("  📡 Nodo servidor iniciado: #{nombre_nodo}")
        iniciar()

      {:error, razon} ->
        IO.puts("  ❌ Error al iniciar nodo: #{inspect(razon)}")
        # Intentar sin distribución
        IO.puts("  ⚠️  Iniciando en modo local...")
        iniciar()
    end
  end

  @doc "Obtiene el hostname de la máquina."
  def obtener_hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  @doc "Muestra las conexiones activas."
  def conexiones do
    nodos = Node.list()

    IO.puts("\n  📡 Nodos conectados: #{length(nodos)}")

    Enum.each(nodos, fn nodo ->
      IO.puts("    → #{nodo}")
    end)

    if Enum.empty?(nodos) do
      IO.puts("    (ninguno)")
    end

    nodos
  end
end
