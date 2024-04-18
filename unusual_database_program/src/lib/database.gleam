import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor.{type Next}
import gleam/result

pub type Database = Dict(String, String)

pub type Request {
  Insert(String, String)
  Retrieve(String, Subject(String))
}

pub fn new(version: String) -> Database {
  dict.new()
  |> dict.insert("version", version)
}

pub fn start(database: Database) {
  actor.start(database, loop)
}

fn loop(request: Request, database: Database) -> Next(Request, Database) {
  case request {
    Insert(key, value) -> {
      database
      |> dict.insert(key, value)
      |> actor.continue()
    }

    Retrieve(key, subject) -> {
      database
      |> dict.get(key)
      |> result.unwrap("")
      |> process.send(subject, _)

      actor.continue(database)
    }
  }
}
