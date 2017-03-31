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

- Install Ruby with Bundler

## Getting Started

Setup Ruby server (only need to do this once):

    make ruby

Run the Ruby server:

    make run_ruby

Run the Ruby tests:

    make test_ruby


# TODO
index

concision
error messages
error handling
fault tolerance
performance
