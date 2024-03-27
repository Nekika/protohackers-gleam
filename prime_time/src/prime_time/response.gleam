import gleam/bytes_builder
import gleam/json

pub type Response {
  Failure(cause: String)
  Success(prime: Bool)
}

pub fn from_result(result: Result(Bool, String)) -> Response {
  case result {
    Ok(prime) -> Success(prime)
    Error(cause) -> Failure(cause)
  }
}
 
pub fn encode(response: Response) -> bytes_builder.BytesBuilder {
  response
  |> response_to_json()
  |> json.to_string()
  |> bytes_builder.from_string()
  |> bytes_builder.append_string("\n")
}

fn response_to_json(response: Response) -> json.Json {
  case response {
    Failure(cause) -> failure_to_json(cause)
    Success(prime) -> success_to_json(prime)
  }
}

fn failure_to_json(cause: String) -> json.Json {
  json.object([
    #("error", json.string(cause))
  ])
}

fn success_to_json(prime: Bool) -> json.Json {
  json.object([
    #("method", json.string("isPrime")),
    #("prime", json.bool(prime))
  ])
}
