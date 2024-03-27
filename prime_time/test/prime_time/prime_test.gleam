import gleeunit/should

import prime_time/prime

fn is_test(number: Int, expected: Bool) {
  prime.is(number)
  |> should.equal(expected)
}

pub fn is_1_test() {
  is_test(1, True)
}

pub fn is_2_test() {
  is_test(2, True)
}

pub fn is_negative_test() {
  is_test(-3124, False)
}

pub fn is_7491_test() {
  is_test(7491, False)
}

pub fn is_1_000_000_000_test() {
  is_test(1_000_000_000, False)
}

