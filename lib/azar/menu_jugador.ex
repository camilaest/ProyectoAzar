defmodule Azar.MenuJugador do

  def menu_jugador do
    IO.puts("""

    ==================================
            MENÚ JUGADOR
    ==================================

    1. Registrarse
    2. Iniciar sesión
    3. Volver al menú principal

    ==================================

    """)

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do
      "1" ->
        registrarse()
        pausa()
        menu_jugador()

      "2" ->
        jugador = iniciar_sesion()
        if jugador != nil do
          menu_sesion(jugador)
        else
          pausa()
          menu_jugador()
        end

      "3" ->
        Estructura.menu_principal()

      _ ->
        IO.puts("\nOpción inválida.")
        pausa()
        menu_jugador()
    end
  end

  # Menú que aparece DESPUÉS de iniciar sesión
  def menu_sesion(jugador) do
    IO.puts("""

    ==================================
        BIENVENIDO, #{jugador.nombre}
    ==================================

    1. Ver sorteos disponibles
    2. Comprar billete/fracción
    3. Ver mi historial de apuestas
    4. Ver mis premios ganados
    5. Cerrar sesión

    ==================================

    """)

    opcion =
      IO.gets("Seleccione una opción: ")
      |> String.trim()

    case opcion do
      "1" ->
        ver_sorteos()
        pausa()
        menu_sesion(jugador)

      "2" ->
        comprar_billete(jugador)
        pausa()
        menu_sesion(jugador)

      "3" ->
        ver_historial(jugador)
        pausa()
        menu_sesion(jugador)

      "4" ->
        ver_premios(jugador)
        pausa()
        menu_sesion(jugador)

      "5" ->
        IO.puts("\nSesión cerrada. ¡Hasta luego!")
        menu_jugador()

      _ ->
        IO.puts("\nOpción inválida.")
        pausa()
        menu_sesion(jugador)
    end
  end

  # =========================
  # REGISTRARSE
  # =========================

  defp registrarse do
    IO.puts("\n===== REGISTRO DE JUGADOR =====\n")
    jugador = Azar.Jugador.ingresar("Ingrese sus datos")
    existentes = Azar.Jugador.cargar_jugadores("jugadores.json")

    ya_existe = Enum.any?(existentes, fn j ->
      j.identificacion == jugador.identificacion
    end)

    if ya_existe do
      IO.puts("\nEsa identificación ya está registrada.")
    else
      Azar.Jugador.escribir_json(existentes ++ [jugador], "jugadores.json")
      IO.puts("\n¡Jugador registrado exitosamente!")
    end
  end

  # =========================
  # INICIAR SESIÓN
  # =========================

  defp iniciar_sesion do
    IO.puts("\n===== INICIAR SESIÓN =====\n")
    identificacion = IO.gets("Identificación: ") |> String.trim()
    contraseña = IO.gets("Contraseña: ") |> String.trim()

    jugadores = Azar.Jugador.cargar_jugadores("jugadores.json")

    caso = Enum.find(jugadores, fn j ->
      j.identificacion == identificacion and j.contraseña == contraseña
    end)

    case caso do
      nil ->
        IO.puts("\nIdentificación o contraseña incorrecta.")
        nil

      jugador ->
        IO.puts("\n¡Bienvenido, #{jugador.nombre}!")
        jugador
    end
  end

  # =========================
  # VER SORTEOS
  # =========================

  defp ver_sorteos do
    IO.puts("\n===== SORTEOS DISPONIBLES =====\n")
    sorteos = Azar.SorteoServer.sorteos_disponibles()

    if sorteos == [] do
      IO.puts("No hay sorteos disponibles por el momento.")
    else
      Enum.each(sorteos, fn s ->
        IO.puts("ID: #{s.id} | Nombre: #{s.nombre} | Precio: $#{s.precio_billete} | Fracciones: #{s.fracciones_totales}")
      end)
    end
  end

  # =========================
  # COMPRAR BILLETE
  # =========================

  defp comprar_billete(jugador) do
    IO.puts("\n===== COMPRAR BILLETE/FRACCIÓN =====\n")

    sorteos = Azar.SorteoServer.sorteos_disponibles()

    if sorteos == [] do
      IO.puts("No hay sorteos disponibles para comprar.")
    else
      Enum.each(sorteos, fn s ->
        IO.puts("ID: #{s.id} | #{s.nombre} | $#{s.precio_billete} | Fracciones por billete: #{s.fracciones_totales}")
      end)

      sorteo_id =
        IO.gets("\nIngrese el ID del sorteo: ")
        |> String.trim()
        |> String.to_integer()

      numero =
        IO.gets("Ingrese el número de billete (ej: 001): ")
        |> String.trim()

      cantidad =
        IO.gets("Cantidad de fracciones a comprar: ")
        |> String.trim()
        |> String.to_integer()

      case Azar.SorteoServer.comprar_fraccion(sorteo_id, numero, jugador.identificacion, cantidad) do
        {:ok, apuesta} ->
          IO.puts("\n✅ ¡Compra exitosa!")
          IO.puts("   Apuesta ID : #{apuesta.id}")
          IO.puts("   Billete    : #{apuesta.numero_billete}")
          IO.puts("   Fracciones : #{apuesta.fracciones}")
          IO.puts("   Monto      : $#{apuesta.monto}")

        {:error, razon} ->
          IO.puts("\n❌ No se pudo completar la compra: #{razon}")
      end
    end
  end

  # =========================
  # HISTORIAL DE APUESTAS
  # =========================

  defp ver_historial(jugador) do
    IO.puts("\n===== MI HISTORIAL DE APUESTAS =====\n")

    apuestas = Azar.Apuesta.historial_jugador(jugador.identificacion)
    total = Azar.Apuesta.total_gastado(jugador.identificacion)

    if apuestas == [] do
      IO.puts("No tienes apuestas registradas.")
    else
      Enum.each(apuestas, fn a ->
        IO.puts("ID: #{a.id} | Sorteo: #{a.sorteo_id} | Billete: #{a.numero_billete} | Fracciones: #{a.fracciones} | $#{a.monto} | Estado: #{a.estado}")
      end)
      IO.puts("\n💰 Total gastado: $#{total}")
    end
  end

  # =========================
  # PREMIOS GANADOS
  # =========================

  defp ver_premios(jugador) do
    IO.puts("\n===== MIS PREMIOS GANADOS =====\n")

    apuestas = Azar.Apuesta.historial_jugador(jugador.identificacion)

    premios =
      apuestas
      |> Enum.filter(fn a -> a.estado == :activa end)
      |> Enum.flat_map(fn apuesta ->
        case Azar.SorteoServer.consultar_sorteo(apuesta.sorteo_id) do
          {:ok, sorteo} ->
            case Azar.Sorteo.verificar_ganador(sorteo, apuesta.numero_billete) do
              {:ganador, premio} -> [%{apuesta: apuesta, premio: premio}]
              :no_ganador -> []
            end
          _ -> []
        end
      end)

    if premios == [] do
      IO.puts("No tienes premios ganados aún.")
    else
      Enum.each(premios, fn p ->
        IO.puts("🏆 Billete #{p.apuesta.numero_billete} → #{p.premio.premio} | $#{p.premio.valor}")
      end)
    end
  end

  # =========================
  # PAUSA
  # =========================

  defp pausa do
    IO.gets("\nPresione ENTER para continuar...")
  end

end
