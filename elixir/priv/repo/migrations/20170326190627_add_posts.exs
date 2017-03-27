defmodule Pastebin.Repo.Migrations.AddPosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :name
      add :body
    end
  end
end
