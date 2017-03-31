extern crate iron;
extern crate persistent;
extern crate router;
extern crate r2d2;
extern crate r2d2_sqlite;
extern crate rusqlite;
extern crate uuid;

use iron::prelude::*;
use iron::status;
use iron::modifiers::Header;
use iron::headers::ContentType;
use std::io::Read;
use std::env;
use std::process;

pub struct ConnectionPool;
impl iron::typemap::Key for ConnectionPool {
    type Value = r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>;
}

fn post_pastebin(req: &mut Request) -> IronResult<Response> {
    let pool = req.get::<persistent::Read<ConnectionPool>>().unwrap();
    let conn = pool.get().unwrap();

    let mut req_body = String::new();
    req.body.read_to_string(&mut req_body).unwrap();

    let id = uuid::Uuid::new_v4().to_string();
    let sql = "INSERT INTO posts VALUES ($1, $2)";

    match conn.execute(sql, &[&id, &req_body]) {
        Ok(_) => Ok(Response::with((status::Created, Header(ContentType::plaintext()), id))),
        Err(_) => Ok(Response::with((status::ServiceUnavailable, Header(ContentType::plaintext()), ""))),
    }
}

fn get_pastebin(req: &mut Request) -> IronResult<Response> {
    let pool = req.get::<persistent::Read<ConnectionPool>>().unwrap();
    let conn = pool.get().unwrap();

    let id = req.extensions.get::<router::Router>().unwrap().find("id").unwrap();

    let sql = "SELECT body FROM posts WHERE id = $1";
    match conn.query_row(sql, &[&id], |row| -> String { row.get(0) }) {
        Ok(body) => Ok(Response::with((status::Ok, Header(ContentType::plaintext()), body))),
        Err(_) => Ok(Response::with((status::NotFound, Header(ContentType::plaintext()), "Not found\n"))),
    }
}

fn main() {
    let mut router = router::Router::new();
    router.post("/", post_pastebin, "post_pastebin");
    router.get("/:id", get_pastebin, "get_pastebin");

    let config = r2d2::Config::default();
    let manager = r2d2_sqlite::SqliteConnectionManager::new("./db.sqlite3");
    let pool = r2d2::Pool::new(config, manager).unwrap();
    let conn = pool.get().unwrap();
    let sql = "CREATE TABLE IF NOT EXISTS posts (id TEXT, body BLOB)";
    conn.execute(sql, &[]).unwrap();
    let sql = "CREATE UNIQUE INDEX IF NOT EXISTS posts_id ON posts (id)";
    conn.execute(sql, &[]).unwrap();

    let mut middleware = Chain::new(router);
    middleware.link_before(persistent::Read::<ConnectionPool>::one(pool));

    match env::var("PORT") {
        Ok(port) => {
            let port: u16 = port.parse().expect("PORT must be an integer");
            println!("Starting server on port {}...", port);
            Iron::new(middleware).http(("localhost", port)).unwrap();
        },
        Err(_) => {
            println!("PORT environment variable must be set");
            process::exit(1);
        },
    }
}
