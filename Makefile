PORT := 3000

.PHONY: prereqs ruby elixir test perf

prereqs:
	echo TODO

ruby:
	cd ruby/ && bundle install && bundle exec ruby app.rb -p $(PORT)

elixir:
	cd elixir/ && mix deps.get && PORT=$(PORT) mix run --no-halt

test:
	PORT=$(PORT) bundle exec rspec spec --format=doc

perf:
	echo TODO
