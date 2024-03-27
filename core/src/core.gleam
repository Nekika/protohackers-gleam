import gleam/erlang/process
import gleam/result

import glisten/socket.{type ListenSocket, type Socket, type SocketReason}
import glisten/socket/options.{ActiveMode, Passive}
import glisten/tcp

pub type Handler(a) =  fn(Socket) -> a

pub type Receiver(a) =  fn(BitArray) -> a

pub fn listen(port: Int, handler: Handler(a)) -> Result(Nil, SocketReason) {
  use listener <- result.try(tcp.listen(port, [ActiveMode(Passive)]))
  accept_until_error(listener, handler)
}

pub fn accept_until_error(listener: ListenSocket, handler: Handler(a)) -> Result(Nil, SocketReason) {
  use socket <- result.try(tcp.accept(listener))
  process.start(linked: True, running: fn() {
    handler(socket)
    tcp.close(socket)
  })
  accept_until_error(listener, handler)
}
