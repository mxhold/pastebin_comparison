PORT := 3000

.PHONY: prereqs ruby elixir test

prereqs:
	echo TODO

ruby:
	cd ruby/ && bundle install && bundle exec ruby app.rb -p $(PORT)

elixir:
	cd elixir/ && mix deps.get && mix run 

test:
	PORT=$(PORT) bundle exec rspec spec --format=doc
