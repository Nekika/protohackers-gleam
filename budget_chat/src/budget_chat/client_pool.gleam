import gleam/bool
import gleam/list
import gleam/otp/actor.{type Next}
import gleam/result

import budget_chat/client.{type Client, Connection, Clients, type Message}

pub type Action {
  Add(Client)
  Send(Message)
}

pub opaque type ClientPool {
  ClientPool(clients: List(Client))
}

pub fn start() {
  actor.start(ClientPool([]), actor_loop)
}

fn actor_loop(action: Action, pool: ClientPool) -> Next(Action, ClientPool) {
  let pool = case action {
    Add(new_client) -> handle_add(pool, new_client)
    Send(message) -> handle_send(pool, message)
  }

  actor.continue(pool)
}

fn broadcast(pool: ClientPool, message: Message) {
  pool.clients
  |> list.each(client.send(_, message))
}

fn handle_add(pool: ClientPool, new_client: Client) -> ClientPool {
  let send_result = client.send(new_client, Clients(pool.clients))
  use <- bool.guard(result.is_error(send_result), pool)
  broadcast(pool, Connection(new_client))
  ClientPool([new_client, ..pool.clients])
}

fn handle_send(pool: ClientPool, message: Message) -> ClientPool {
  broadcast(pool, message)
  pool
}
