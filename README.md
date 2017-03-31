# pastebin comparison

This repository contains implementations of a simple pastebin server written in:

- Ruby
- Elixir
- Rust

This provides a small, concrete way to compare how conventions in these three languages shape code written in them.

## Specification

Here are the requirements of the pastebin server:

- POST / with the body of a post creates a post and returns the post's ID
- GET /{post_id} returns the body of the post with the provided ID

An OpenAPI v2.0 specification is available in the `specification.yaml` file.

To make the comparison easiest and for minimal setup, all are implemented using SQLite.

## Prerequisites

- Ruby >= 2.1
- Bundler >= 1
- Elixir >= 1
- Rust >= 1

To check if you have all the prereqs, run `make prereqs`.

## Getting Started

Setup everything:

    make

Run the Ruby server:

    make ruby

Run the Elixir server:

    make elixir

Run the Rust server:

    make rust

These will all run on port 3000 by default. To override, set the PORT like:

    make PORT=3001 ruby

To run the test suite:

    make test

This will test the server running on port 3000 by default. To override:

    make PORT=3001 test

To run the performance benchmark, in separate terminals run:

    make PORT=3000 ruby
    make PORT=3001 elixir
    make PORT=3002 rust
    make perf


# TODO

concision
error messages
error handling
fault tolerance
performance
