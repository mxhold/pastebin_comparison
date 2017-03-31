PORT := 3000

.PHONY: prereqs ruby elixir rust test perf

setup:
	bundle install
	cd ruby/ && bundle install
	cd elixir/ && mix deps.get
	cd rust/ && cargo build

prereqs:
	echo TODO

ruby:
	cd ruby/ && bundle exec ruby app.rb -p $(PORT)

elixir:
	cd elixir/ && PORT=$(PORT) mix run --no-halt

rust:
	cd rust/ && PORT=$(PORT) cargo run

test:
	PORT=$(PORT) bundle exec rspec spec --format=doc

perf:
	echo TODO
