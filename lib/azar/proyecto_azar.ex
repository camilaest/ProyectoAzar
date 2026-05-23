defmodule ProyectoAzar do
  @moduledoc """
  Módulo raíz del proyecto Azar S.A.
  Punto de entrada principal de la aplicación.
  """

  @doc "Inicia la aplicación completa con menú interactivo."
  def iniciar do
    Estructura.main()
  end

  @doc "Inicia solo el servidor (para modo distribuido)."
  def iniciar_servidor do
    Azar.Servidor.iniciar()
  end

  @doc "Inicia como nodo servidor distribuido."
  def iniciar_nodo_servidor(nombre \\ "servidor") do
    Azar.Servidor.iniciar_nodo(nombre)
  end

  @doc "Inicia como nodo cliente y conecta al servidor."
  def iniciar_nodo_cliente(nombre \\ "cliente1", servidor \\ nil) do
    Azar.Cliente.iniciar_nodo(nombre)

    if servidor do
      Azar.Cliente.conectar(servidor)
    end
  end
end
