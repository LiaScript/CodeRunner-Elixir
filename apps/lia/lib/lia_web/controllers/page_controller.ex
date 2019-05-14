defmodule LiaWeb.PageController do
  use LiaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def course(conn, _params) do
    render(conn, "course.html")
  end
end
