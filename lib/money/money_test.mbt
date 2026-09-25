// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
test "money construction and zero" {
  let m = Money::of(12345, "CNY")
  assert_eq(m.minor, 12345)
  assert_eq(m.currency, "CNY")
  assert_eq(Money::zero("CNY"), Money::of(0, "CNY"))
}

///|
test "money add subtract negate scale" {
  let a = Money::of(12345, "CNY")
  let b = Money::of(100, "CNY")
  assert_eq(a.add(b), Money::of(12445, "CNY"))
  assert_eq(a.sub(b), Money::of(12245, "CNY"))
  assert_eq(a.neg(), Money::of(-12345, "CNY"))
  assert_eq(a.scale(3), Money::of(37035, "CNY"))
}

///|
test "money sign predicates" {
  assert_eq(Money::of(1, "CNY").is_positive(), true)
  assert_eq(Money::of(-1, "CNY").is_negative(), true)
  assert_eq(Money::of(0, "CNY").is_zero(), true)
}

///|
test "round_div half up" {
  assert_eq(round_div(5, 2, round_half_up()), 3)
  assert_eq(round_div(4, 2, round_half_up()), 2)
  assert_eq(round_div(7, 2, round_half_up()), 4)
  assert_eq(round_div(-5, 2, round_half_up()), -3)
}

///|
test "round_div down and up" {
  assert_eq(round_div(5, 2, round_down()), 2)
  assert_eq(round_div(-5, 2, round_down()), -2)
  assert_eq(round_div(5, 2, round_up()), 3)
  assert_eq(round_div(-5, 2, round_up()), -3)
}

///|
test "round_div half even" {
  assert_eq(round_div(5, 2, round_half_even()), 2)
  assert_eq(round_div(7, 2, round_half_even()), 4)
  assert_eq(round_div(6, 2, round_half_even()), 3)
}

///|
test "round to yuan / jiao / fen" {
  let m = Money::of(12345, "CNY")
  assert_eq(m.round_to(0, round_half_up()), Money::of(12300, "CNY"))
  assert_eq(m.round_to(1, round_half_up()), Money::of(12350, "CNY"))
  assert_eq(m.round_to(2, round_half_up()), Money::of(12345, "CNY"))
}

///|
test "format with grouping and fraction" {
  assert_eq(Money::of(1234567, "CNY").format(), "12,345.67")
  assert_eq(Money::of(-12345, "CNY").format(), "-123.45")
  assert_eq(Money::of(5, "CNY").format(), "0.05")
  assert_eq(Money::of(0, "CNY").format(), "0.00")
  assert_eq(Money::of(100000000, "CNY").format(), "1,000,000.00")
}
