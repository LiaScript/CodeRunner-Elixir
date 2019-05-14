defmodule LiaWeb.Router do
  use LiaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiaWeb do
    pipe_through :browser

    get "/", PageController, :index
    get("/course", PageController, :course)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiaWeb do
  #   pipe_through :api
  # end
end
