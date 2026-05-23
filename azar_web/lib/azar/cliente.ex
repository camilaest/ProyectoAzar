defmodule Azar.Cliente do
  @moduledoc """
  Módulo para el nodo cliente distribuido de Azar S.A.
  Se conecta al servidor y envía solicitudes remotas.
  """

  alias Azar.Logger

  @timeout 10_000

  @doc """
  Conecta al nodo servidor.
  Uso: Azar.Cliente.conectar("servidor@hostname")
  """
  def conectar(nombre_servidor) do
    nodo = String.to_atom(nombre_servidor)

    IO.puts("\n  📡 Intentando conectar a #{nodo}...")

    case Node.connect(nodo) do
      true ->
        Logger.registrar("Conexión cliente", "Conectado exitosamente a #{nodo}")
        IO.puts("  ✅ Conectado a #{nodo}")
        :ok

      false ->
        Logger.error("Conexión cliente", "No se pudo conectar a #{nodo}")
        IO.puts("  ❌ No se pudo conectar a #{nodo}")
        {:error, "No se pudo conectar al servidor"}

      :ignored ->
        IO.puts("  ⚠️  Nodo local no está en modo distribuido")
        {:error, "El nodo local no está en modo distribuido"}
    end
  end

  @doc """
  Inicia el nodo como cliente distribuido.
  Uso: Azar.Cliente.iniciar_nodo("cliente1")
  """
  def iniciar_nodo(nombre \\ "cliente1") do
    hostname = Azar.Servidor.obtener_hostname()
    nombre_nodo = :"#{nombre}@#{hostname}"

    case Node.start(nombre_nodo) do
      {:ok, _} ->
        Node.set_cookie(:azar_cookie)
        IO.puts("  📡 Nodo cliente iniciado: #{nombre_nodo}")
        :ok

      {:error, razon} ->
        IO.puts("  ❌ Error al iniciar nodo cliente: #{inspect(razon)}")
        {:error, razon}
    end
  end

  # ════════════════════════════════════════════
  # Solicitudes Remotas al Servidor
  # ════════════════════════════════════════════

  @doc "Crea un sorteo en el servidor remoto."
  def crear_sorteo_remoto(attrs) do
    llamar_servidor(:sorteo_server, {:crear, attrs})
  end

  @doc "Lista sorteos del servidor remoto."
  def listar_sorteos_remoto do
    llamar_servidor(:sorteo_server, :listar)
  end

  @doc "Consulta un sorteo del servidor remoto."
  def consultar_sorteo_remoto(id) do
    llamar_servidor(:sorteo_server, {:consultar, id})
  end

  @doc "Compra fracción en el servidor remoto."
  def comprar_fraccion_remoto(sorteo_id, billete, jugador_id, fracciones) do
    llamar_servidor(:sorteo_server, {:comprar, sorteo_id, billete, jugador_id, fracciones})
  end

  @doc "Cierra un sorteo en el servidor remoto."
  def cerrar_sorteo_remoto(id) do
    llamar_servidor(:sorteo_server, {:cerrar, id})
  end

  # ─── Helper privado para llamadas remotas ───

  defp llamar_servidor(nombre_global, mensaje) do
    case :global.whereis_name(nombre_global) do
      :undefined ->
        {:error, "Servidor no disponible. ¿Está el nodo servidor corriendo?"}

      pid ->
        try do
          resultado = GenServer.call(pid, mensaje, @timeout)
          resultado
        catch
          :exit, {:timeout, _} ->
            Logger.error("Cliente", "Timeout al contactar servidor")
            {:error, "Timeout: el servidor no respondió a tiempo"}

          :exit, reason ->
            Logger.error("Cliente", "Error de conexión: #{inspect(reason)}")
            {:error, "Error de conexión con el servidor"}
        end
    end
  end
end
