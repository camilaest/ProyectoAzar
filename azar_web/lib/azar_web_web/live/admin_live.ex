defmodule AzarWebWeb.AdminLive do
  use AzarWebWeb, :live_view
  alias Azar.{SorteoServer, Reportes, Util}

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5000, :refresh)
    
    {:ok, assign(socket, 
      sorteos: SorteoServer.listar_sorteos(),
      tab: "listar",
      error: nil,
      success: nil
    )}
  end

  def handle_info(:refresh, socket) do
    {:noreply, assign(socket, sorteos: SorteoServer.listar_sorteos())}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-900 text-white flex">
      <!-- Admin Sidebar -->
      <div class="w-64 bg-slate-800 border-r border-slate-700 p-6 flex flex-col justify-between hidden md:flex">
        <div>
          <div class="mb-10 text-center">
            <h1 class="text-3xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-red-400 to-orange-500">Azar Admin</h1>
            <p class="text-xs text-slate-400 mt-1">Panel de Control</p>
          </div>

          <nav class="space-y-2">
            <button phx-click="set_tab" phx-value-tab="listar" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "listar", do: "bg-blue-500/10 text-blue-400 border border-blue-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-list-bullet" class="w-5 h-5 mr-3" /> Ver Sorteos
            </button>
            <button phx-click="set_tab" phx-value-tab="crear" class={"w-full text-left px-4 py-3 rounded-lg font-medium flex items-center transition-colors " <> if @tab == "crear", do: "bg-green-500/10 text-green-400 border border-green-500/20", else: "text-slate-400 hover:bg-slate-700/50 hover:text-slate-200"}>
              <.icon name="hero-plus-circle" class="w-5 h-5 mr-3" /> Crear Sorteo
            </button>
          </nav>
        </div>
        
        <button phx-click="logout" class="flex items-center text-slate-400 hover:text-red-400 transition-colors">
          <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 mr-2" /> Salir al Home
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

        <%= case @tab do %>
          <% "listar" -> %>
            <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-list-bullet" class="w-6 h-6 mr-2 text-blue-400" /> Todos los Sorteos</h3>
            <div class="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden">
              <table class="w-full text-left text-sm text-slate-300">
                <thead class="bg-slate-900 text-slate-400 text-xs uppercase">
                  <tr><th class="px-6 py-4">ID</th><th class="px-6 py-4">Nombre</th><th class="px-6 py-4">Estado</th><th class="px-6 py-4 text-right">Acciones</th></tr>
                </thead>
                <tbody class="divide-y divide-slate-700">
                  <%= for s <- @sorteos do %>
                    <tr class="hover:bg-slate-700/30">
                      <td class="px-6 py-4 font-medium text-blue-400">#<%= s.id %></td>
                      <td class="px-6 py-4"><%= s.nombre %></td>
                      <td class="px-6 py-4">
                        <span class={"px-2 py-1 rounded text-xs font-bold " <> 
                          if to_string(s.estado) == "pendiente", do: "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30", else: "bg-green-500/20 text-green-400 border border-green-500/30"
                        }>
                          <%= String.upcase(to_string(s.estado)) %>
                        </span>
                        <%= if to_string(s.estado) == "realizado" and s.ganadores do %>
                          <div class="mt-2 text-xs text-slate-400">
                            <strong>Ganadores:</strong><br/>
                            <%= for g <- s.ganadores do %>
                              - <%= g["premio"] %>: <span class="text-emerald-400 font-mono"><%= g["numero_ganador"] %></span><br/>
                            <% end %>
                          </div>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 text-right space-x-2">
                        <%= if to_string(s.estado) == "pendiente" do %>
                          <button phx-click="cerrar" phx-value-id={s.id} class="text-xs bg-red-500/20 text-red-400 hover:bg-red-500 hover:text-white px-3 py-1.5 rounded transition-colors border border-red-500/30">
                            Cerrar y Sortear
                          </button>
                        <% else %>
                          <span class="text-xs text-slate-500">Ya cerrado</span>
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

          <% "crear" -> %>
            <div class="max-w-2xl mx-auto">
              <h3 class="text-2xl font-bold mb-6 text-white flex items-center"><.icon name="hero-plus-circle" class="w-6 h-6 mr-2 text-green-400" /> Crear Nuevo Sorteo</h3>
              <form phx-submit="crear" class="bg-slate-800 p-8 rounded-2xl border border-slate-700 space-y-6">
                <div>
                  <label class="block text-sm font-medium text-slate-400 mb-1">Nombre del Sorteo</label>
                  <input type="text" name="nombre" class="w-full bg-slate-900 border border-slate-600 rounded-lg px-4 py-2.5 text-white focus:border-blue-500" required />
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-slate-400 mb-1">Precio del Billete</label>
                    <input type="number" name="precio" class="w-full bg-slate-900 border border-slate-600 rounded-lg px-4 py-2.5 text-white focus:border-blue-500" required />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-slate-400 mb-1">Cantidad de Billetes</label>
                    <input type="number" name="billetes" class="w-full bg-slate-900 border border-slate-600 rounded-lg px-4 py-2.5 text-white focus:border-blue-500" required />
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-slate-400 mb-1">Fracciones por Billete</label>
                    <input type="number" name="fracciones" class="w-full bg-slate-900 border border-slate-600 rounded-lg px-4 py-2.5 text-white focus:border-blue-500" required />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-slate-400 mb-1">Premio Mayor ($)</label>
                    <input type="number" name="premio1" class="w-full bg-slate-900 border border-slate-600 rounded-lg px-4 py-2.5 text-white focus:border-blue-500" required />
                  </div>
                </div>
                <button type="submit" class="w-full bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-bold py-3 px-4 rounded-lg shadow-lg">
                  Lanzar Sorteo
                </button>
              </form>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("logout", _params, socket), do: {:noreply, push_navigate(socket, to: "/")}
  def handle_event("set_tab", %{"tab" => tab}, socket), do: {:noreply, assign(socket, tab: tab, error: nil, success: nil)}

  def handle_event("cerrar", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    case SorteoServer.cerrar_sorteo(id) do
      {:ok, s} -> {:noreply, assign(socket, success: "Sorteo #{id} cerrado. ¡Ganadores generados!", sorteos: SorteoServer.listar_sorteos())}
      {:error, msg} -> {:noreply, assign(socket, error: msg)}
    end
  end

  def handle_event("crear", %{"nombre" => nombre, "precio" => precio, "billetes" => billetes, "fracciones" => frac, "premio1" => p1}, socket) do
    datos = %{
      nombre: nombre,
      precio_billete: String.to_integer(precio),
      cantidad_billetes: String.to_integer(billetes),
      fracciones_totales: String.to_integer(frac),
      premios: [%{"nombre" => "Premio Mayor", "valor" => String.to_integer(p1)}]
    }
    
    case SorteoServer.crear_sorteo(datos) do
      {:ok, _s} -> {:noreply, assign(socket, tab: "listar", success: "Sorteo creado exitosamente", sorteos: SorteoServer.listar_sorteos())}
      {:error, msg} -> {:noreply, assign(socket, error: msg)}
    end
  end
end
