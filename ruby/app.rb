require "sinatra"
require "securerandom"
require "sqlite3"

configure do
  database_file = "db.sqlite3"
  db = SQLite3::Database.new(database_file)
  db.execute("CREATE TABLE IF NOT EXISTS posts (id TEXT, body BLOB)")
  db.execute("CREATE UNIQUE INDEX IF NOT EXISTS posts_id ON posts (id)")
  set(:db, db)
end

post "/" do
  post_id = SecureRandom.uuid
  post_body = request.body.read

  Sinatra::Application.db.execute(
    "INSERT INTO posts (id, body) VALUES (?, ?)",
    [post_id, post_body]
  )

  content_type "text/plain; charset=utf-8"
  status 201

  "#{request.base_url}/#{post_id}"
end

get "/:post_id" do
  post_id = params["post_id"]

  post_body = Sinatra::Application.db.execute(
    "SELECT body FROM posts WHERE id = ?",
    [post_id]
  ).flatten.first

  if post_body
    content_type "text/plain; charset=utf-8"
    status 200

    post_body
  else
    not_found
  end
end

not_found do
  content_type "text/plain; charset=utf-8"
  status 404

  "Not found\n"
end
