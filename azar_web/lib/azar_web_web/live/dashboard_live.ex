defmodule AzarWebWeb.DashboardLive do
  use AzarWebWeb, :live_view
  alias Azar.{Jugador, SorteoServer, Sorteo, Apuesta}

  def mount(%{"id" => identificacion}, _session, socket) do
    if jugador = Jugador.buscar_por_id(identificacion) do
      if connected?(socket) do
        :timer.send_interval(5000, :refresh)
      end
      
      {:ok, assign(socket, 
        jugador: jugador, 
        sorteos: SorteoServer.filtrar_sorteos({:estado, :pendiente}), 
        apuestas: Apuesta.historial_por_jugador(identificacion),
        tab: "sorteos",
        error: nil,
        success: nil
      )}
    else
      {:ok, push_navigate(socket, to: "/")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/")}
  end

  def handle_info(:refresh, socket) do
    id = socket.assigns.jugador.identificacion
    jugador = Jugador.buscar_por_id(id)
    {:noreply, assign(socket, 
      jugador: jugador, 
      sorteos: SorteoServer.filtrar_sorteos({:estado, :pendiente}),
      apuestas: Apuesta.historial_por_jugador(id)
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-900 text-white flex">
      <!-- Sidebar -->
      <div class="w-64 bg-slate-800 border-r border-slate-700 p-6 flex flex-col justify-between hidden md:flex">
        <div>
          <div class="mb-10 text-center">
            <h1 class="text-3xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-500">Azar S.A.</h1>
            <p class="text-xs text-slate-400 mt-1">Dashboard de Jugador</p>
          </div>
          
          <div class="bg-slate-700/50 rounded-xl p-4 mb-8 text-center border border-slate-600">
            <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full mx-auto mb-3 flex items-center justify-center text-xl font-bold shadow-lg">
              <%= String.at(@jugador.nombre, 0) %>
            </div>
            <h2 class="font-bold text-lg text-slate-200"><%= @jugador.nombre %></h2>
            <p class="text-sm text-slate-400">ID: <%= @jugador.identificacion %></p>
          </div>

          <nav class="space-y-2">
            <button phx-click="set_tab" phx-value-tab="sorteos" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "sorteos", do: "bg-blue-500/10 text-blue-400 border border-blue-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-ticket" class="w-5 h-5 mr-3" /> Sorteos
            </button>
            <button phx-click="set_tab" phx-value-tab="apuestas" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "apuestas", do: "bg-purple-500/10 text-purple-400 border border-purple-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-clock" class="w-5 h-5 mr-3" /> Mis Apuestas
            </button>
            <button phx-click="set_tab" phx-value-tab="premios" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "premios", do: "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-trophy" class="w-5 h-5 mr-3" /> Premios
            </button>
            <button phx-click="set_tab" phx-value-tab="resultados" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "resultados", do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-star" class="w-5 h-5 mr-3" /> Sorteos Anteriores
            </button>
          </nav>
        </div>
        
        <button phx-click="logout" class="flex items-center text-slate-400 hover:text-red-400 transition-colors">
          <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 mr-2" /> Salir
        </button>
      </div>

      <!-- Main Content -->
      <div class="flex-1 overflow-y-auto p-8 relative">
        <div class="absolute top-4 right-8 z-50 flex flex-col space-y-2">
          <%= if @error do %>
            <div class="bg-red-500/90 backdrop-blur text-white px-6 py-3 rounded-lg shadow-xl flex items-center animate-fade-in-down">
              <.icon name="hero-exclamation-circle" class="w-5 h-5 mr-2" /> <%= @error %>
            </div>
          <% end %>
          <%= if @success do %>
            <div class="bg-green-500/90 backdrop-blur text-white px-6 py-3 rounded-lg shadow-xl flex items-center animate-fade-in-down">
              <.icon name="hero-check-circle" class="w-5 h-5 mr-2" /> <%= @success %>
            </div>
          <% end %>
        </div>

        <div class="flex justify-between items-center mb-10 bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-lg">
          <div>
            <p class="text-slate-400 text-sm font-medium mb-1">Saldo Disponible</p>
            <h2 class="text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-emerald-500">
              $<%= :erlang.float_to_binary(@jugador.saldo * 1.0, decimals: 2) %>
            </h2>
          </div>
          
          <form phx-submit="recargar" class="flex items-center gap-2">
            <input type="number" name="monto" class="w-32 bg-slate-900 border border-slate-600 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-green-500 text-sm" placeholder="$ Monto" min="1" required />
            <button type="submit" class="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-lg font-medium text-sm transition-colors shadow-lg shadow-emerald-500/20 flex items-center">
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Recargar
            </button>
          </form>
        </div>

        <%= case @tab do %>
          <% "sorteos" -> %>
            <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-sparkles" class="w-6 h-6 mr-2 text-blue-400" /> Sorteos Activos</h3>
            <%= if Enum.empty?(@sorteos) do %>
              <div class="bg-slate-800 border border-slate-700 rounded-2xl p-10 text-center">
                <.icon name="hero-ticket" class="w-16 h-16 mx-auto text-slate-600 mb-4" />
                <h4 class="text-xl font-medium text-slate-300">No hay sorteos disponibles</h4>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <%= for sorteo <- @sorteos do %>
                  <div class="bg-slate-800 border border-slate-700 rounded-2xl p-6 shadow-xl relative overflow-hidden flex flex-col">
                    <div class="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 rounded-full blur-2xl -mr-10 -mt-10"></div>
                    <div class="flex justify-between items-start mb-4">
                      <div>
                        <span class="bg-blue-500/20 text-blue-400 text-xs font-bold px-2 py-1 rounded-md mb-2 inline-block border border-blue-500/30">ID: <%= sorteo.id %></span>
                        <h4 class="text-xl font-bold text-slate-100"><%= sorteo.nombre %></h4>
                      </div>
                      <div class="text-right">
                        <p class="text-xs text-slate-400">Precio/Fracción</p>
                        <p class="text-lg font-bold text-emerald-400">$<%= Sorteo.precio_fraccion(sorteo) %></p>
                      </div>
                    </div>
                    <form phx-submit="comprar" class="mt-auto space-y-3 bg-slate-900/50 p-4 rounded-xl border border-slate-700">
                      <input type="hidden" name="sorteo_id" value={sorteo.id} />
                      <div class="flex gap-2">
                        <div class="flex-1">
                          <input type="text" name="numero" placeholder="Billete Ej: 001" class="w-full bg-slate-800 border border-slate-600 rounded px-3 py-1.5 text-sm" required />
                        </div>
                        <div class="w-1/3">
                          <input type="number" name="fracciones" min="1" max={sorteo.fracciones_totales} value="1" class="w-full bg-slate-800 border border-slate-600 rounded px-3 py-1.5 text-sm" required />
                        </div>
                      </div>
                      <button type="submit" class="w-full bg-blue-600 hover:bg-blue-500 text-white font-medium py-2 rounded text-sm">Comprar Billete</button>
                    </form>
                  </div>
                <% end %>
              </div>
            <% end %>

          <% "apuestas" -> %>
            <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-clock" class="w-6 h-6 mr-2 text-purple-400" /> Historial de Apuestas</h3>
            <div class="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden">
              <table class="w-full text-left text-sm text-slate-300">
                <thead class="bg-slate-900 text-slate-400 text-xs uppercase">
                  <tr><th class="px-6 py-4">Fecha</th><th class="px-6 py-4">Sorteo ID</th><th class="px-6 py-4">Billete</th><th class="px-6 py-4">Fracciones</th><th class="px-6 py-4 text-right">Inversión</th></tr>
                </thead>
                <tbody class="divide-y divide-slate-700">
                  <%= for a <- @apuestas do %>
                    <tr class="hover:bg-slate-700/30">
                      <td class="px-6 py-4"><%= a.fecha %></td>
                      <td class="px-6 py-4 font-medium text-blue-400">#<%= a.sorteo_id %></td>
                      <td class="px-6 py-4"><%= a.numero_billete %></td>
                      <td class="px-6 py-4"><%= a.fracciones %></td>
                      <td class="px-6 py-4 text-right text-emerald-400 font-bold">$<%= a.monto %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

          <% "premios" -> %>
            <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-trophy" class="w-6 h-6 mr-2 text-yellow-400" /> Mis Premios Ganados</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <%= for premio <- @jugador.premios_ganados do %>
                <div class="bg-gradient-to-br from-yellow-500/20 to-orange-600/20 border border-yellow-500/30 rounded-2xl p-6 flex items-center shadow-lg">
                  <div class="w-16 h-16 bg-yellow-500/20 rounded-full flex items-center justify-center mr-6">
                    <.icon name="hero-star" class="w-8 h-8 text-yellow-400" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-300 mb-1">¡Felicidades!</p>
                    <h4 class="text-xl font-bold text-yellow-400 mb-1"><%= premio["premio"] || "Premio" %></h4>
                    <p class="text-sm text-slate-400">Sorteo ID: <%= premio["sorteo_id"] || "N/A" %> | Billete: <%= premio["numero_ganador"] || "N/A" %></p>
                  </div>
                  <div class="ml-auto text-right">
                    <p class="text-xs text-slate-400">Valor</p>
                    <p class="text-2xl font-black text-emerald-400">$<%= premio["valor"] %></p>
                  </div>
                </div>
              <% end %>
              <%= if Enum.empty?(@jugador.premios_ganados) do %>
                <p class="text-slate-500 col-span-2 text-center py-10 bg-slate-800 rounded-2xl border border-slate-700">Aún no tienes premios. ¡Sigue participando!</p>
              <% end %>
            </div>

          <% "resultados" -> %>
            <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-star" class="w-6 h-6 mr-2 text-emerald-400" /> Resultados de Sorteos</h3>
            <div class="space-y-6">
              <%= for sorteo <- SorteoServer.filtrar_sorteos({:estado, :realizado}) do %>
                <div class="bg-slate-800 border border-slate-700 rounded-2xl p-6 shadow-lg">
                  <div class="border-b border-slate-700 pb-4 mb-4">
                    <h4 class="text-xl font-bold text-slate-100"><%= sorteo.nombre %> <span class="text-sm font-normal text-slate-400 ml-2">(ID: <%= sorteo.id %>)</span></h4>
                  </div>
                  <%= if sorteo.ganadores && length(sorteo.ganadores) > 0 do %>
                    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                      <%= for g <- sorteo.ganadores do %>
                        <div class="bg-slate-900/50 border border-emerald-500/30 rounded-lg p-4">
                          <p class="text-emerald-400 font-bold mb-1"><%= g["premio"] %></p>
                          <p class="text-sm text-slate-300">Billete Ganador: <span class="text-white font-mono font-bold text-lg"><%= g["numero_ganador"] %></span></p>
                          <p class="text-xs text-slate-500 mt-1">Premio de $<%= g["valor"] %></p>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <p class="text-slate-500 italic">No hubo ganadores registrados para este sorteo.</p>
                  <% end %>
                </div>
              <% end %>
              <%= if Enum.empty?(SorteoServer.filtrar_sorteos({:estado, :realizado})) do %>
                <p class="text-slate-500 text-center py-10 bg-slate-800 rounded-2xl border border-slate-700">Aún no hay sorteos finalizados.</p>
              <% end %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("logout", _params, socket), do: {:noreply, push_navigate(socket, to: "/")}
  def handle_event("set_tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab, error: nil, success: nil)}

  def handle_event("recargar", %{"monto" => monto_str}, socket) do
    monto = case Float.parse(monto_str) do
      {val, _} -> val
      :error -> 0.0
    end
    if monto > 0 do
      {:ok, jugador_act} = Jugador.actualizar_saldo(socket.assigns.jugador, monto)
      Jugador.actualizar_en_json(jugador_act)
      {:noreply, assign(socket, jugador: jugador_act, success: "Recarga exitosa", error: nil)}
    else
      {:noreply, assign(socket, error: "Monto inválido", success: nil)}
    end
  end

  def handle_event("comprar", %{"sorteo_id" => id_str, "numero" => numero, "fracciones" => frac_str}, socket) do
    sorteo_id = String.to_integer(id_str)
    fracciones = String.to_integer(frac_str)
    jugador = socket.assigns.jugador

    case SorteoServer.consultar_sorteo(sorteo_id) do
      {:ok, sorteo} ->
        monto = Sorteo.precio_fraccion(sorteo) * fracciones
        if monto > jugador.saldo do
          {:noreply, assign(socket, error: "Saldo insuficiente.", success: nil)}
        else
          case SorteoServer.comprar_fraccion(sorteo_id, numero, jugador.identificacion, fracciones) do
            {:ok, compra} ->
              {:ok, jugador_act} = Jugador.actualizar_saldo(jugador, -compra.monto)
              Jugador.actualizar_en_json(jugador_act)
              Apuesta.registrar_apuesta(jugador.identificacion, sorteo_id, compra.billete, fracciones, compra.monto)
              {:noreply, assign(socket, jugador: jugador_act, apuestas: Apuesta.historial_por_jugador(jugador_act.identificacion), success: "Compra exitosa!", error: nil)}
            {:error, msg} -> {:noreply, assign(socket, error: msg, success: nil)}
          end
        end
      _ -> {:noreply, assign(socket, error: "Sorteo no encontrado", success: nil)}
    end
  end
end
