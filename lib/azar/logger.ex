defmodule Azar.Logger do
  @moduledoc """
  Módulo de bitácora del sistema Azar S.A.

  Registra todas las operaciones relevantes del sistema con nivel de
  severidad, fecha/hora, módulo de origen, solicitud y resultado.

  ## Niveles disponibles

    - `:info`    — Operaciones exitosas normales (crear sorteo, comprar fracción, etc.)
    - `:warning` — Situaciones anómalas que no detienen el sistema (sorteo no encontrado,
                   apuesta rechazada, datos inválidos, etc.)
    - `:error`   — Fallos graves o inesperados del sistema.

  ## Formato de cada entrada en bitácora

      [INFO]    2026-05-18 14:32:05 - SorteoServer - Crear sorteo - OK - ID: 123456
      [WARNING] 2026-05-18 14:33:01 - SorteoServer - Compra fracción - ERROR: Sorteo no disponible
      [ERROR]   2026-05-18 14:33:45 - SorteoServer - Finalizar sorteo - ERROR: Sorteo no encontrado

  ## Uso

      # Operación exitosa
      Azar.Logger.info("SorteoServer", "Crear sorteo", "OK - ID: \#{sorteo.id}")

      # Rechazo de negocio (no es un crash, pero hay que registrarlo)
      Azar.Logger.warning("SorteoServer", "Compra fracción", "Sorteo ya cerrado")

      # Fallo inesperado
      Azar.Logger.error("SorteoServer", "Cargar desde disco", "Archivo corrupto: sorteo_99.json")

  ## Compatibilidad con la API anterior

  La función `registrar/2` se mantiene para que el código existente
  de `SorteoServer` no necesite cambios. Internamente usa nivel `:info`.

      Azar.Logger.registrar("Crear sorteo", "OK - ID: 123")
  """

  @archivo_bitacora "lib/bitacora.txt"

  # Ancho del campo de nivel en la salida (para alinear columnas)
  @etiquetas %{
    info:    "[INFO]   ",
    warning: "[WARNING]",
    error:   "[ERROR]  "
  }

  # API Pública — niveles explícitos

  @doc """
  Registra una operación exitosa con nivel `:info`.

  ## Parámetros
    - `modulo`    — Nombre del módulo que origina el evento (ej: "SorteoServer")
    - `solicitud` — Descripción de la operación realizada (ej: "Crear sorteo")
    - `resultado` — Resultado de la operación (ej: "OK - ID: 123456")

  ## Ejemplo
      Azar.Logger.info("SorteoServer", "Finalizar sorteo 99", "OK - Ganadores asignados")
  """
  def info(modulo, solicitud, resultado) do
    registrar_con_nivel(:info, modulo, solicitud, resultado)
  end

  @doc """
  Registra una situación anómala que no detiene el sistema, con nivel `:warning`.

  Usar cuando una operación es rechazada por reglas de negocio:
  sorteo no encontrado, billete sin fracciones, apuesta ya devuelta, etc.

  ## Ejemplo
      Azar.Logger.warning("SorteoServer", "Compra fracción", "Billete sin fracciones disponibles")
  """
  def warning(modulo, solicitud, resultado) do
    registrar_con_nivel(:warning, modulo, solicitud, resultado)
  end

  @doc """
  Registra un fallo grave o inesperado del sistema con nivel `:error`.

  Usar ante excepciones, archivos corruptos, estados inconsistentes
  u otras condiciones que no deberían ocurrir en operación normal.

  ## Ejemplo
      Azar.Logger.error("SorteoServer", "Cargar desde disco", "JSON inválido en sorteo_99.json")
  """
  def error(modulo, solicitud, resultado) do
    registrar_con_nivel(:error, modulo, solicitud, resultado)
  end

  @doc """
  Compatibilidad con la API anterior del Logger.

  Registra la entrada con nivel `:info` y módulo "SorteoServer" (el único
  caller original).

  ## Ejemplo
      Azar.Logger.registrar("Crear sorteo", "OK - ID: 123")
  """
  def registrar(solicitud, resultado) do
    registrar_con_nivel(:info, "SorteoServer", solicitud, resultado)
  end

  # Función privada central

  defp registrar_con_nivel(nivel, modulo, solicitud, resultado) do
    etiqueta = Map.get(@etiquetas, nivel, "[INFO]   ")
    timestamp = obtener_timestamp()

    linea = "#{etiqueta} #{timestamp} - #{modulo} - #{solicitud} - #{resultado}"

    # Mostrar en consola con color según nivel
    linea |> colorear(nivel) |> IO.puts()

    # Guardar en bitácora (sin códigos de color, texto plano)
    File.write(@archivo_bitacora, linea <> "\n", [:append])

    :ok
  end

  # Formatea la fecha/hora actual como string legible: "2026-05-18 14:32:05"
  defp obtener_timestamp do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
    |> String.replace("T", " ")
    |> String.replace("Z", "")
  end

  # Aplica código de color ANSI a la línea según el nivel (solo en consola)
  defp colorear(linea, :info),    do: "\e[32m#{linea}\e[0m"   # verde
  defp colorear(linea, :warning), do: "\e[33m#{linea}\e[0m"   # amarillo
  defp colorear(linea, :error),   do: "\e[31m#{linea}\e[0m"   # rojo
  defp colorear(linea, _),        do: linea
end
