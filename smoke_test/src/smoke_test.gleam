import gleam/bytes_builder
import gleam/result

import core
import glisten/tcp

const port = 45678

pub fn main() {
  use socket <- core.listen(port)
  use data <- result.try(tcp.receive(socket, 0))
  bytes_builder.from_bit_array(data)
  |> tcp.send(socket, _)
}
