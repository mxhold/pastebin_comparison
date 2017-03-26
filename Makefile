PORT := 3000

.PHONY: ruby test

ruby:
	cd ruby/ && bundle install && bundle exec ruby app.rb -p $(PORT)

test:
	PORT=$(PORT) bundle exec rspec spec --format=doc
