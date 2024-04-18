import gleam/dynamic.{type Dynamic, element, int, string}
import gleam/result

pub type Option {
  Active(Bool)
  Binary
  Inet
  Inet6
  List
}

pub opaque type Socket

pub type IpAddress {
  Ipv4(Int, Int, Int, Int)
  Ipv6(Int, Int, Int, Int, Int, Int, Int, Int)
}

pub type Message {
 Message(address: IpAddress, port: Int, data: String)
}

fn decode_ipv4_address(value: Dynamic) -> Result(IpAddress, dynamic.DecodeErrors) {
  value
  |> dynamic.decode4(Ipv4, element(0, int), element(1, int), element(2, int), element(3, int))
}

fn decode_ipv6_address(value: Dynamic) -> Result(IpAddress, dynamic.DecodeErrors) {
  value
  |> dynamic.decode8(Ipv6, element(0, int), element(1, int), element(2, int), element(3, int), element(4, int), element(5, int), element(6, int), element(7, int))
}

fn decode_ip_address(value: Dynamic) -> Result(IpAddress, dynamic.DecodeErrors) {
  decode_ipv4_address(value)
  |> result.lazy_or(fn() { decode_ipv6_address(value) })
}

fn decode_receive_data(value: Dynamic) -> Result(Message, Nil) {
  value
  |> dynamic.decode3(Message, element(0, decode_ip_address), element(1, int), element(2, string))
  |> result.nil_error()
}

pub fn open(port: Int) -> Result(Socket, Nil) {
 open_options(port, [Active(False), Binary])
}

@external(erlang, "gen_udp", "open")
pub fn open_options(port: Int, options: List(Option)) -> Result(Socket, Nil)

pub fn receive(socket: Socket, length: Int) -> Result(Message, Nil) {
  do_receive(socket, length)
  |> result.nil_error()
  |> result.map(dynamic.from)
  |> result.then(decode_receive_data)
}

@external(erlang, "gen_udp", "recv")
fn do_receive(socket: Socket, length: Int) -> Result(Dynamic, Nil)

@external(erlang, "gen_udp", "recv")
pub fn receive_timeout(socket: Socket, length: Int, timeout: Int) -> Result(Message, Nil)

pub fn send(socket: Socket, address: IpAddress, port: Int, packet: String) -> Result(Nil, Nil) {
  let address = case address {
    Ipv4(a, b, c, d) -> dynamic.from(#(a, b, c, d))
    Ipv6(a, b, c, d, e, f, g, h) -> dynamic.from(#(a, b, c, d, e, f, g, h))
  }

  let packet = packet <> "\n"

  do_send(socket, address, port, packet)
}

@external(erlang, "gen_udp", "send")
fn do_send(socket: Socket, address: Dynamic, port: Int, packet: String) -> Result(Nil, Nil)
