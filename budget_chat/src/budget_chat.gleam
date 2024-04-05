import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result

import core

import budget_chat/client.{type Message}
import budget_chat/client_pool.{type Action, Send}

pub fn main() {
  let assert Ok(pool) = client_pool.start()

  let assert Ok(forwarder) = actor.start(pool, fn(message: Message, pool: Subject(Action)) {
    process.send(pool, Send(message))
    actor.continue(pool)
  })

  process.start(linked: True, running: fn() {
    use socket <- core.listen(1234)
    use new_client <- result.map(client.register(socket))
    process.send(pool, client_pool.Add(new_client))
    client.start(new_client, forwarder)
  })

  process.sleep_forever()
}
