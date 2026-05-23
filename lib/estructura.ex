defmodule Estructura do
  @moduledoc """
  Modulo principal de Azar S.A. - Menu principal y flujo de jugador.
  """

  alias Azar.{Util, Autenticacion, SorteoServer, Apuesta, Notificador, Suscripcion, Logger}

  def main do
    # Iniciar GenServers
    iniciar_servicios()
    menu_principal()
  end

  defp iniciar_servicios do
    case GenServer.whereis(Azar.SorteoServer) do
      nil -> SorteoServer.start_link([])
      _ -> :ok
    end
    case GenServer.whereis(Azar.Notificador) do
      nil -> Notificador.start_link([])
      _ -> :ok
    end
    :ok
  end

  def menu_principal do
    IO.puts("""

    ===============================
        AZAR S.A. - Sorteos
    ===============================
    1. Ingresar como Administrador
    2. Ingresar como Jugador
    3. Salir
    ===============================
    """)

    opcion = Util.ingresar("  Seleccione una opcion: ", :entero)

    case opcion do
      1 ->
        Azar.Admin.menu()
        menu_principal()
      2 ->
        menu_jugador_login()
        menu_principal()
      3 ->
        IO.puts("\n  Gracias por usar Azar S.A. Hasta luego!\n")
        :ok
      _ ->
        IO.puts("\n  Opcion no valida.")
        menu_principal()
    end
  end

  # === MENU JUGADOR (login/registro) ===

  defp menu_jugador_login do
    IO.puts("""

    ===============================
        MENU JUGADOR
    ===============================
    1. Registrarse
    2. Iniciar sesion
    3. Volver
    ===============================
    """)

    case Util.ingresar("  Opcion: ", :entero) do
      1 -> registrar_jugador()
      2 -> login_jugador()
      3 -> :volver
      _ ->
        IO.puts("  Opcion no valida.")
        menu_jugador_login()
    end
  end

  defp registrar_jugador do
    IO.puts("\n  === REGISTRO DE JUGADOR ===\n")
    nombre = Util.ingresar("  Nombre completo: ", :texto)
    id = Util.ingresar("  Identificacion: ", :texto)
    pass = Util.ingresar("  Contrasena (min 4 caracteres): ", :texto)
    tarjeta = ingresar_tarjeta_valida()

    case Autenticacion.registrar(nombre, id, pass, tarjeta) do
      {:ok, jugador} ->
        IO.puts("\n  Registro exitoso! Bienvenido #{jugador.nombre}")
        # Suscribir a notificaciones
        try do Suscripcion.suscribir_jugador(jugador.identificacion) catch _, _ -> :ok end
        menu_jugador(jugador)
      {:error, msg} ->
        IO.puts("\n  Error: #{msg}")
        menu_jugador_login()
    end
  end

  defp ingresar_tarjeta_valida do
    tarjeta = Util.ingresar("  Tarjeta de credito: ", :texto)
    case Autenticacion.validar_tarjeta(tarjeta) do
      :ok -> tarjeta
      {:error, msg} ->
        IO.puts("  Error: #{msg}. Por favor intente de nuevo.")
        ingresar_tarjeta_valida()
    end
  end

  defp login_jugador do
    IO.puts("\n  === INICIO DE SESION ===\n")
    id = Util.ingresar("  Identificacion: ", :texto)
    pass = Util.ingresar("  Contrasena: ", :texto)

    case Autenticacion.iniciar_sesion(id, pass) do
      {:ok, jugador} ->
        IO.puts("\n  Bienvenido de nuevo, #{jugador.nombre}!")
        try do Suscripcion.suscribir_jugador(jugador.identificacion) catch _, _ -> :ok end
        menu_jugador(jugador)
      {:error, msg} ->
        IO.puts("\n  Error: #{msg}")
        menu_jugador_login()
    end
  end

  # === MENU JUGADOR (sesion activa) ===

  defp menu_jugador(jugador) do
    IO.puts("""

    ===============================
      Jugador: #{jugador.nombre}
      Saldo: $#{jugador.saldo}
    ===============================
    1. Ver sorteos disponibles
    2. Comprar billete/fraccion
    3. Ver historial de apuestas
    4. Ver premios ganados
    5. Ver notificaciones
    6. Recargar saldo
    7. Cerrar sesion
    ===============================
    """)

    case Util.ingresar("  Opcion: ", :entero) do
      1 -> ver_sorteos(jugador)
      2 -> comprar_billete(jugador)
      3 -> ver_historial(jugador)
      4 -> ver_premios(jugador)
      5 -> ver_notificaciones(jugador)
      6 -> recargar_saldo(jugador)
      7 ->
        IO.puts("\n  Sesion cerrada.")
        Logger.registrar("Cerrar sesion", "Jugador #{jugador.nombre}")
        :ok
      _ ->
        IO.puts("  Opcion no valida.")
        menu_jugador(jugador)
    end
  end

  defp ver_sorteos(jugador) do
    sorteos = SorteoServer.filtrar_sorteos({:estado, :pendiente})
    if Enum.empty?(sorteos) do
      IO.puts("\n  No hay sorteos disponibles.\n")
    else
      IO.puts("\n  === SORTEOS DISPONIBLES ===")
      Enum.each(sorteos, fn s ->
        IO.puts("  ID: #{s.id} | #{s.nombre} | Fecha: #{s.fecha} | Precio: $#{s.precio_billete}")
      end)
    end
    menu_jugador(jugador)
  end

  defp comprar_billete(jugador) do
    sorteo_id = Util.ingresar("\n  ID del sorteo: ", :entero)

    case SorteoServer.consultar_sorteo(sorteo_id) do
      {:ok, sorteo} ->
        if to_string(sorteo.estado) != "pendiente" do
          IO.puts("  El sorteo no esta abierto para compras.")
          menu_jugador(jugador)
        else
          precio_frac = Azar.Sorteo.precio_fraccion(sorteo)
          IO.puts("  Sorteo: #{sorteo.nombre} | Precio fraccion: $#{precio_frac}")
          numero = Util.ingresar("  Numero de billete (ej: 001): ", :texto)
          fracciones = Util.ingresar("  Cantidad de fracciones: ", :entero)
          monto = precio_frac * fracciones

          if monto > jugador.saldo do
            IO.puts("  Saldo insuficiente. Necesita $#{monto}, tiene $#{jugador.saldo}")
            menu_jugador(jugador)
          else
            case SorteoServer.comprar_fraccion(sorteo_id, numero, jugador.identificacion, fracciones) do
              {:ok, compra} ->
                # Descontar saldo
                {:ok, jugador_act} = Azar.Jugador.actualizar_saldo(jugador, -compra.monto)
                Azar.Jugador.actualizar_en_json(jugador_act)
                # Registrar apuesta
                Apuesta.registrar_apuesta(jugador.identificacion, sorteo_id, compra.billete, fracciones, compra.monto)
                IO.puts("  Compra exitosa! #{compra.fracciones} fraccion(es) del billete ##{compra.billete} por $#{compra.monto}")
                menu_jugador(jugador_act)
              {:error, msg} ->
                IO.puts("  Error: #{msg}")
                menu_jugador(jugador)
            end
          end
        end
      {:error, msg} ->
        IO.puts("  Error: #{msg}")
        menu_jugador(jugador)
    end
  end

  defp ver_historial(jugador) do
    apuestas = Apuesta.historial_por_jugador(jugador.identificacion)
    if Enum.empty?(apuestas) do
      IO.puts("\n  No tiene apuestas registradas.\n")
    else
      IO.puts("\n  === HISTORIAL DE APUESTAS ===")
      Enum.each(apuestas, fn a ->
        IO.puts("  Sorteo: #{a.sorteo_id} | Billete: ##{a.numero_billete} | Fracciones: #{a.fracciones} | Monto: $#{a.monto} | Fecha: #{a.fecha}")
      end)
    end
    menu_jugador(jugador)
  end

  defp ver_premios(jugador) do
    premios = jugador.premios_ganados
    if Enum.empty?(premios) do
      IO.puts("\n  No tiene premios ganados aun.\n")
    else
      IO.puts("\n  === PREMIOS GANADOS ===")
      Enum.each(premios, fn p ->
        IO.puts("  #{inspect(p)}")
      end)
    end
    menu_jugador(jugador)
  end

  defp ver_notificaciones(jugador) do
    try do
      notifs = Notificador.obtener_notificaciones(jugador.identificacion)
      if Enum.empty?(notifs) do
        IO.puts("\n  No tiene notificaciones.\n")
      else
        IO.puts("\n  === NOTIFICACIONES ===")
        Enum.each(notifs, fn n ->
          IO.puts("  [#{Map.get(n,"fecha")}] #{Map.get(n,"mensaje")}")
        end)
      end
    catch
      _, _ -> IO.puts("\n  Servicio de notificaciones no disponible.\n")
    end
    menu_jugador(jugador)
  end

  defp recargar_saldo(jugador) do
    monto = Util.ingresar("\n  Monto a recargar: $", :entero)
    if monto > 0 do
      {:ok, jugador_act} = Azar.Jugador.actualizar_saldo(jugador, monto * 1.0)
      Azar.Jugador.actualizar_en_json(jugador_act)
      IO.puts("  Saldo recargado! Nuevo saldo: $#{jugador_act.saldo}")
      menu_jugador(jugador_act)
    else
      IO.puts("  El monto debe ser positivo.")
      menu_jugador(jugador)
    end
  end
end
