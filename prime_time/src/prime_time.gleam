import gleam/result

import core
import prime_time/prime
import prime_time/request
import prime_time/response

import glisten/socket
import glisten/tcp

const port = 45678

type HandleReason {
  Receive
  Request(request.RequestReason)
}

pub fn main() {
  use socket <- core.listen(port)
  handle(socket)
}

fn handle(socket: socket.Socket) {
  let result =
    socket
    |> receive_message()
    |> result.then(process_message)
    |> send_response(socket)

  case result {
    Ok(_) -> handle(socket)
    Error(_) -> Nil
  }
}

fn receive_message(socket: socket.Socket) -> Result(BitArray, HandleReason) {
  socket
  |> tcp.receive(_, 0)
  |> result.replace_error(Receive)
}

fn process_message(message: BitArray) -> Result(Bool, HandleReason) {
  message
  |> request.from_bit_array()
  |> result.map(fn(request) { prime.is(request.number) })
  |> result.map_error(Request)
}

fn reason_to_string(reason: HandleReason) -> String {
  case reason {
    Receive -> "Failed to receive message."
    Request(request_reason) -> request.reason_to_string(request_reason)
  }
}

fn send_response(result: Result(Bool, HandleReason), socket: socket.Socket) -> Result(Bool, HandleReason) {
  result
  |> result.map_error(reason_to_string)
  |> response.from_result()
  |> response.encode()
  |> tcp.send(socket, _)

  result
}
