defmodule Pastebin do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Sqlitex.Server, ['db.sqlite3', [name: Sqlitex.Server]]),
      worker(__MODULE__, [], function: :run),
    ]

    opts = [strategy: :one_for_one, name: Pastebin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def run do
    sql = "CREATE TABLE IF NOT EXISTS posts (id TEXT, body BLOB)"
    Sqlitex.Server.query(Sqlitex.Server, sql)

    sql = "CREATE UNIQUE INDEX IF NOT EXISTS posts_id ON posts (id)"
    Sqlitex.Server.query(Sqlitex.Server, sql)

    port = case System.get_env("PORT") do
      nil -> raise "PORT environment variable must be set"
      port -> String.to_integer(port)
    end

    IO.puts "Starting server on port #{port}..."

    {:ok, _} = Plug.Adapters.Cowboy.http Pastebin.AppRouter, [], port: port
  end

  defmodule AppRouter do
    use Plug.Router

    plug :match
    plug :dispatch

    post "/" do
      {:ok, body, _} = Plug.Conn.read_body(conn)
      post_id = UUID.uuid4()

      sql = "INSERT INTO posts (id, body) VALUES ($1, $2)"
      Sqlitex.Server.query(Sqlitex.Server, sql, bind: [post_id, body])

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(201, "#{conn.scheme}://#{get_req_header(conn, "host")}/#{post_id}")
    end

    match "/:post_id" do
      sql = "SELECT body FROM posts WHERE id = $1"
      {:ok, rows} = Sqlitex.Server.query(Sqlitex.Server, sql, bind: [post_id])
      case rows do
        [] -> not_found(conn)
        [[{:body, body}]] ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(200, body)
      end
    end

    match _ do
      not_found(conn)
    end

    def not_found(conn) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "Not found\n")
    end
  end
end
