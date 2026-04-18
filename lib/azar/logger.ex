defmodule Azar.Logger do
  @doc """
  Módulo encargado de cumplir con el requisito de bitácora del sistema.
  """
  def registrar(solicitud, resultado) do
    # Obtenemos fecha y hora para el registro
    tiempo = DateTime.utc_now() |> DateTime.to_string()

    # Formateamos la línea según el PDF: fecha - hora - solicitud - resultado
    linea = "#{tiempo} - Solicitud: #{solicitud} - Resultado: #{resultado}"

    # REQUISITO 1: Mostrar en pantalla
    IO.puts(linea)

    # REQUISITO 2: Guardar en archivo de texto (bitácora/log)
    # Usamos [:append] para que no borre lo anterior, sino que escriba abajo.
    File.write("bitacora.txt", linea <> "\n", [:append])
  end
end
