import gleam/dynamic
import gleam/function
import gleam/json
import gleam/result

pub type Request {
  Request(method: String, number: Int)
}

pub type RequestReason {
  Decode
  Method
}

pub fn from_bit_array(data: BitArray) -> Result(Request, RequestReason) {
  use request <- result.then(decode(data))
  validate(request)
}

fn decode(data: BitArray) -> Result(Request, RequestReason) {
  data
  |> json.decode_bits(from: _, using: decoder)
  |> result.replace_error(Decode)
}

fn decoder(value: dynamic.Dynamic) -> Result(Request, dynamic.DecodeErrors) {
  use method <- result.then(decode_method(value))
  use number <- result.map(decode_number(value))
  Request(method, number)
}

fn decode_method(value: dynamic.Dynamic) -> Result(String, dynamic.DecodeErrors) {
  dynamic.field("method", dynamic.string)
  |> function.apply1(value)
}

fn decode_number(value: dynamic.Dynamic) -> Result(Int, dynamic.DecodeErrors) {
  dynamic.field("number", dynamic.int)
  |> function.apply1(value)
}

fn validate(request: Request) -> Result(Request, RequestReason) {
  case request.method {
    "isPrime" -> Ok(request)
    _ -> Error(Method)
  }
}

pub fn reason_to_string(reason: RequestReason) -> String {
  case reason {
    Decode -> "Failed to decode the message."
    Method -> "Unsupported method."
  }
}
