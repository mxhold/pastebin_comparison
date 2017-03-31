extern crate iron;
extern crate persistent;
extern crate router;
extern crate r2d2;
extern crate r2d2_sqlite;
extern crate rusqlite;
extern crate uuid;

use iron::prelude::*;
use iron::{headers, status};
use iron::modifiers::Header;
use std::io::Read;
use std::env;
use std::process;

pub struct ConnectionPool;
impl iron::typemap::Key for ConnectionPool {
    type Value = r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>;
}

struct DatabaseConnection {
    conn: r2d2::PooledConnection<r2d2_sqlite::SqliteConnectionManager>,
}

impl DatabaseConnection {
    fn new(pool: &r2d2::Pool<r2d2_sqlite::SqliteConnectionManager>) -> DatabaseConnection {
        DatabaseConnection { conn: pool.get().unwrap() }
    }

    fn setup_database(&self) -> Result<i32, rusqlite::Error> {
        let query = "CREATE TABLE IF NOT EXISTS posts (id TEXT, body BLOB)";
        self.conn.execute(query, &[])
    }

    fn insert_paste(&self, body: &str) -> Result<String, rusqlite::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let query = "INSERT INTO posts VALUES ($1, $2)";
        self.conn.execute(query, &[&id, &body]).and(Ok(id))
    }

    fn get_paste_body_by_id(&self, id: &str) -> Option<String> {
        let query = "SELECT body FROM posts WHERE id = $1";
        self.conn.query_row(query, &[&id], |row| row.get(0)).ok()
    }
}

fn post_pastebin(req: &mut Request) -> IronResult<Response> {
    let pool = req.get::<persistent::Read<ConnectionPool>>().unwrap();
    let conn = DatabaseConnection::new(&pool);

    let mut req_body = String::new();
    req.body.read_to_string(&mut req_body).unwrap();

    match conn.insert_paste(&req_body) {
        Ok(id) => Ok(Response::with((status::Created, Header(headers::ContentType::plaintext()), id))),
        Err(_) => Ok(Response::with((status::ServiceUnavailable, Header(headers::ContentType::plaintext()), ""))),
    }
}

fn get_pastebin(req: &mut Request) -> IronResult<Response> {
    let pool = req.get::<persistent::Read<ConnectionPool>>().unwrap();
    let conn = DatabaseConnection::new(&pool);

    let id = req.extensions.get::<router::Router>().unwrap().find("id").unwrap();

    match conn.get_paste_body_by_id(&id) {
        Some(body) => Ok(Response::with((status::Ok, Header(headers::ContentType::plaintext()), body))),
        None => Ok(Response::with((status::NotFound, Header(headers::ContentType::plaintext()), "Not found\n"))),
    }
}

fn main() {
    let mut router = router::Router::new();
    router.post("/", post_pastebin, "post_pastebin");
    router.get("/:id", get_pastebin, "get_pastebin");

    let config = r2d2::Config::default();
    let manager = r2d2_sqlite::SqliteConnectionManager::new("./db.sqlite3");
    let pool = r2d2::Pool::new(config, manager).unwrap();
    DatabaseConnection::new(&pool).setup_database().unwrap();

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
