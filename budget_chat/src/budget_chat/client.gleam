import gleam/bit_array
import gleam/bool
import gleam/bytes_builder
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option
import gleam/result
import gleam/string

import glisten/socket.{type Socket}
import glisten/tcp

pub opaque type Client {
  Client(socket: Socket, username: String)
}

pub type Message {
  Connection(Client)
  Chat(Client, String)
  Clients(List(Client))
  Disconnection(Client)
}

pub fn register(socket: Socket) -> Result(Client, Nil) {
  use _ <- result.then(ask_username(socket))
  use username <- result.then(receive_username(socket))
  use username <- result.map(validate_username(username))
  Client(socket, username)
}

pub fn send(client: Client, message: Message) -> Result(Nil, Nil) {
  case message {
    Chat(sender, _) if sender == client -> Ok(Nil)

    _ -> {
      message
      |> message_to_string()
      |> bytes_builder.from_string()
      |> tcp.send(client.socket, _)
      |> result.nil_error()
    }
  }
}

pub fn start(client: Client, subject: Subject(Message)) {
  chat_loop(client, subject)
}

pub fn stop(client: Client) {
  let _ = tcp.close(client.socket)

  Nil
}

fn ask_username(socket: Socket) -> Result(Nil, Nil) {
  "Enter a username : "
  |> bytes_builder.from_string()
  |> tcp.send(socket, _)
  |> result.nil_error()
}

fn receive_username(socket: Socket) -> Result(String, Nil) {
  socket
  |> tcp.receive(0)
  |> result.nil_error()
  |> result.then(fn(data) {
    data
    |> bit_array.to_string()
    |> result.nil_error()
  })
  |> result.map(string.trim)
}

fn validate_username(username: String) -> Result(String, Nil) {
  use <- bool.guard(string.length(username) < 1, Error(Nil))
  Ok(username)
}

fn chat_loop(client: Client, subject: Subject(Message)) -> Nil {
  let receive_result =
    client.socket
    |> tcp.receive(0)
    |> result.nil_error()
    |> result.then(fn(data) {
      data
      |> bit_array.to_string()
      |> result.nil_error()
    })
    |> result.map(string.trim_right)

  case receive_result {
    Ok(content) -> {
      process.send(subject, Chat(client, content))
      chat_loop(client, subject)
    }
    Error(_) -> {
      process.send(subject, Disconnection(client))
    }
  }
}

fn message_to_string(message: Message) -> String {
  case message {
    Clients(clients) -> {
      let usernames = 
        clients
        |> list.map(fn(client) { client.username })
        |> string.join(", ")
        |> string.to_option()
        |> option.unwrap("/")

      "* Connected users : " <> usernames <> "\n"
    }

    Connection(client) -> "* " <> client.username <> " connected\n"

    Chat(client, content) -> "[" <> client.username <> "] " <> content <> "\n"

    Disconnection(client) -> "* " <> client.username <> " disconnected.\n"
  }
}

