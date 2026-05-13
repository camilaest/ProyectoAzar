defmodule ProyectoAzar.Application do
  use Application

  def start(_type, _args) do
    children = [
      Azar.SorteoServer,
      Azar.Notificador
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
