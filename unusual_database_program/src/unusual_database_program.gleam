import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/pair
import gleam/string
import gleam/string_builder

import lib/database.{Insert, type Request, Retrieve}
import lib/udp.{type Message, type Socket}

const version = "1.0"

pub fn main() {
  let assert Ok(database) = database.new(version) |> database.start()
  
  let assert Ok(socket) = udp.open(1234)

  process.start(linked: True, running: fn() { listen(socket, database) })
  
  process.sleep_forever()
}

fn listen(socket: Socket, database: Subject(Request)) {
  case udp.receive(socket, 1000) {
    Ok(message) -> {
      process.start(linked: True, running: fn() { handle_message(socket, message, database) })

      listen(socket, database)
    }
    _ -> Nil
  }
}

fn handle_message(socket: Socket, message: Message, database: Subject(Request)) -> Nil {
  case string.split_once(message.data, "=") {
    Ok(pair) -> {
      let #(key, value) = pair.map_second(pair, string.trim)

      use <- bool.guard(key == "version", Nil)
      
      process.send(database, Insert(key, value))
    }

    Error(_) -> {
      let key = string.trim(message.data)

      let value = process.call(database, Retrieve(key, _), 100)

      let packet = 
        string_builder.new()
        |> string_builder.append(key)
        |> string_builder.append("=")
        |> string_builder.append(value)
        |> string_builder.to_string()

      let _ = udp.send(socket, message.address, message.port, packet)

      Nil
    }
  }
}
