defmodule Azar.Logger do
  @moduledoc """
  Módulo de bitácora del sistema Azar S.A.
  Registra operaciones con nivel de log, fecha/hora, módulo y resultado.
  Guarda en pantalla y en archivo de texto.
  """

  @archivo_bitacora "lib/bitacora.txt"

  @doc """
  Registra una operación con nivel :info (por defecto).
  Formato: [NIVEL] FECHA HORA - Módulo - Solicitud - Resultado
  """
  def registrar(solicitud, resultado, nivel \\ :info) do
    tiempo = DateTime.utc_now() |> DateTime.to_string()
    nivel_str = nivel |> to_string() |> String.upcase()

    linea = "[#{nivel_str}] #{tiempo} - Solicitud: #{solicitud} - Resultado: #{resultado}"

    # REQUISITO 1: Mostrar en pantalla
    case nivel do
      :error -> IO.puts(IO.ANSI.red() <> linea <> IO.ANSI.reset())
      :warning -> IO.puts(IO.ANSI.yellow() <> linea <> IO.ANSI.reset())
      _ -> IO.puts(linea)
    end

    # REQUISITO 2: Guardar en archivo de texto (bitácora/log)
    # Usamos [:append] para que no borre lo anterior, sino que escriba abajo.
    File.write(@archivo_bitacora, linea <> "\n", [:append])
  end

  @doc "Registra con nivel :info"
  def info(solicitud, resultado), do: registrar(solicitud, resultado, :info)

  @doc "Registra con nivel :warning"
  def warning(solicitud, resultado), do: registrar(solicitud, resultado, :warning)

  @doc "Registra con nivel :error"
  def error(solicitud, resultado), do: registrar(solicitud, resultado, :error)
end
