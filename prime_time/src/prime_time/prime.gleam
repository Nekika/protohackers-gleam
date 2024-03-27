fn factors(a: Int, b: Int) -> List(Int) {
  case a, b {
    1, _ -> [1]
    _, 1 -> [1]
    x, y if x <= 0 || y <= 0 -> []
    x, y -> case x % y {
      0 -> [y, ..factors(x, y - 1)]
      _ -> factors(x, y - 1)
    }
  }
}

pub fn is(number: Int) -> Bool {
  case factors(number, number / 2) {
    [1] -> True
    _ -> False
  }
}
