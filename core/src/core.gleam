// a function that starts a tcp server and takes a connection handler as an argument
import gleam/erlang/process
import gleam/result

import glisten/socket.{type Socket, type SocketReason}
import glisten/socket/options.{ActiveMode, Passive}
import glisten/tcp

import toolbox/functions

// Start a TCP server on the provided port and blocks until accepting a connection.
// It then start a new process to handle the connection using the provided handler,
// and repeat this forever.
// It returns a SocketReason if it failed to start the server.
//
pub fn listen_forever(port: Int, handler: fn(Socket) -> any) -> SocketReason {
  case tcp.listen(port, [ActiveMode(Passive)]) {
    Ok(listener) -> {
      use <- functions.run_until_error()
      use socket <- result.map(tcp.accept(listener))
      use <- process.start(linked: True)
      handler(socket)
    }
    Error(reason) -> reason
  }
}

// Receive from socket then call handler by passing the received data
// until an error occurs.
//
pub fn receive_until_error(socket: Socket, handler: fn(BitArray) -> any) -> SocketReason {
  use <- functions.run_until_error()
  use data <- result.map(tcp.receive(socket, 0))
  handler(data)
}

