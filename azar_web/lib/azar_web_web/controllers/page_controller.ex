defmodule AzarWebWeb.PageController do
  use AzarWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
