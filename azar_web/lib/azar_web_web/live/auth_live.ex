defmodule AzarWebWeb.AuthLive do
  use AzarWebWeb, :live_view
  alias Azar.Autenticacion

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form_type: :login, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-900 text-white flex flex-col justify-center items-center relative overflow-hidden">
      <!-- Background decorations -->
      <div class="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-blue-600 rounded-full mix-blend-multiply filter blur-[100px] opacity-50 animate-blob"></div>
      <div class="absolute top-[-10%] right-[-10%] w-[40%] h-[40%] bg-purple-600 rounded-full mix-blend-multiply filter blur-[100px] opacity-50 animate-blob animation-delay-2000"></div>
      <div class="absolute bottom-[-20%] left-[20%] w-[40%] h-[40%] bg-pink-600 rounded-full mix-blend-multiply filter blur-[100px] opacity-50 animate-blob animation-delay-4000"></div>

      <div class="z-10 bg-slate-800/60 backdrop-blur-xl border border-slate-700 p-10 rounded-2xl shadow-2xl w-full max-w-md">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-500 mb-2">Azar S.A.</h1>
          <p class="text-slate-400">Plataforma de Sorteos Premium</p>
        </div>

        <div class="flex border-b border-slate-700 mb-6">
          <button phx-click="switch_type" phx-value-type="login" class={"flex-1 py-3 font-semibold transition-colors " <> if @form_type == :login, do: "text-blue-400 border-b-2 border-blue-400", else: "text-slate-500 hover:text-slate-300"}>
            Iniciar Sesión
          </button>
          <button phx-click="switch_type" phx-value-type="register" class={"flex-1 py-3 font-semibold transition-colors " <> if @form_type == :register, do: "text-blue-400 border-b-2 border-blue-400", else: "text-slate-500 hover:text-slate-300"}>
            Registrarse
          </button>
        </div>

        <%= if @error do %>
          <div class="bg-red-500/20 border border-red-500/50 text-red-200 px-4 py-3 rounded-lg mb-6 flex items-center">
            <.icon name="hero-exclamation-circle" class="w-5 h-5 mr-2" />
            <span><%= @error %></span>
          </div>
        <% end %>

        <%= if @form_type == :login do %>
          <form phx-submit="login" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Identificación</label>
              <input type="text" name="identificacion" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all" placeholder="123456789" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Contraseña</label>
              <input type="password" name="contrasena" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all" placeholder="••••••••" required />
            </div>
            <button type="submit" class="w-full bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white font-bold py-3 px-4 rounded-lg shadow-lg transform hover:-translate-y-0.5 transition-all mt-4">
              Entrar
            </button>
          </form>
        <% else %>
          <form phx-submit="register" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Nombre Completo</label>
              <input type="text" name="nombre" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Identificación</label>
              <input type="text" name="identificacion" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Tarjeta de Crédito (13-19 dígitos)</label>
              <input type="text" name="tarjeta" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" required />
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Contraseña</label>
              <input type="password" name="contrasena" class="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" required />
            </div>
            <button type="submit" class="w-full bg-gradient-to-r from-pink-500 to-orange-500 hover:from-pink-600 hover:to-orange-600 text-white font-bold py-3 px-4 rounded-lg shadow-lg transform hover:-translate-y-0.5 transition-all mt-4">
              Crear Cuenta
            </button>
          </form>
        <% end %>

        <div class="mt-8 pt-6 border-t border-slate-700 text-center">
          <a href="/admin" class="text-sm text-slate-400 hover:text-white transition-colors flex items-center justify-center">
            <.icon name="hero-shield-check" class="w-4 h-4 mr-1" />
            Entrar como Administrador
          </a>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("switch_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, form_type: String.to_atom(type), error: nil)}
  end

  def handle_event("login", %{"identificacion" => id, "contrasena" => pass}, socket) do
    case Autenticacion.iniciar_sesion(id, pass) do
      {:ok, jugador} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard?id=#{jugador.identificacion}")}
      {:error, msg} ->
        {:noreply, assign(socket, error: msg)}
    end
  end

  def handle_event("register", %{"nombre" => nombre, "identificacion" => id, "tarjeta" => tarjeta, "contrasena" => pass}, socket) do
    case Autenticacion.registrar(nombre, id, pass, tarjeta) do
      {:ok, jugador} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard?id=#{jugador.identificacion}")}
      {:error, msg} ->
        {:noreply, assign(socket, error: msg)}
    end
  end
end
