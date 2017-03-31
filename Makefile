PORT := 3000

.PHONY: prereqs setup ruby elixir rust test perf

setup: prereqs
	bundle install
	cd ruby/ && bundle install
	cd elixir/ && mix deps.get
	cd rust/ && cargo build

prereqs:
	./prereqs

ruby:
	cd ruby/ && bundle exec ruby app.rb -p $(PORT)

elixir:
	cd elixir/ && PORT=$(PORT) mix run --no-halt

rust:
	cd rust/ && PORT=$(PORT) cargo run

test:
	PORT=$(PORT) bundle exec rspec spec --format=doc

perf:
	bundle exec ruby perf.rb
