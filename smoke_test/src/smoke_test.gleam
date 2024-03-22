import gleam/bytes_builder

import core
import glisten/tcp

const port = 45678

pub fn main() {
  use socket <- core.listen_forever(port)
  use data <- core.receive_until_error(socket)
  
  data
  |> bytes_builder.from_bit_array()
  |> tcp.send(socket, _)
}
