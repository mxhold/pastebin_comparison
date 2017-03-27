defmodule Pastebin do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Pastebin.Repo, []),
      worker(__MODULE__, [], function: :run)
    ]

    opts = [strategy: :one_for_one, name: Pastebin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def run do
    {:ok, _} = Plug.Adapters.Cowboy.http Pastebin.AppRouter, []
  end

  defmodule Repo do
    use Ecto.Repo, otp_app: :pastebin, adapter: Sqlite.Ecto
  end

  defmodule Post do
    use Ecto.Schema

    @primary_key false

    schema "posts" do
      field :id
      field :body
    end

    def insert(body: body) do
      Repo.insert(%Post{body: body})
    end

    def fetch(id) do
      with {:ok, id} <- Ecto.UUID.cast(id),
           {:ok, post} <- do_fetch(id),
           do: {:ok, post}
    end

    defp do_fetch(id) do
      case Repo.get(__MODULE__, id) do
        nil -> :error
        post -> {:ok, post}
      end
    end
  end

  defmodule AppRouter do
    use Plug.Router

    plug :match
    plug :dispatch

    post "/" do
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, post} = Post.insert(body: body)
      send_resp(conn, 201, post.id)
    end

    match "/:post_id" do
      case Post.fetch(post_id) do
        {:ok, post} ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(200, post.body)
        :error -> not_found(conn)
      end
    end

    match _ do
      not_found(conn)
    end

    def not_found(conn) do
      send_resp(conn, 404, "404")
    end
  end
end
