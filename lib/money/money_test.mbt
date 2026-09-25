// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
test "money construction and zero" {
  let m = Money::of(12345, "CNY")
  assert_eq(m.minor(), 12345)
  assert_eq(m.currency(), "CNY")
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
test "currency digits and zero decimal formatting" {
  assert_eq(currency_decimals("CNY"), 2)
  assert_eq(currency_decimals("JPY"), 0)
  assert_eq(currency_decimals("KWD"), 3)
  assert_eq(Money::of(1234567, "JPY").format(), "1,234,567")
  assert_eq(Money::of(-1234567, "JPY").format(), "-1,234,567")
  assert_eq(Money::of(1234567, "KWD").format(), "1,234.567")
  assert_eq(Money::of(-5, "KWD").format(), "-0.005")
  assert_eq(Money::of(1, "KWD").format(), "0.001")
  assert_eq(Money::of(0, "JPY").format(), "0")
}

///|
test "rounding respects currency digits and negative values" {
  let kwd = Money::of(1234567, "KWD")
  assert_eq(kwd.round_to(0, round_half_up()), Money::of(1235000, "KWD"))
  assert_eq(kwd.round_to(2, round_half_up()), Money::of(1234570, "KWD"))
  assert_eq(kwd.round_to(3, round_half_up()), kwd)
  assert_eq(
    Money::of(-125, "CNY").round_to(1, round_half_up()),
    Money::of(-130, "CNY"),
  )
  assert_eq(
    Money::of(5, "JPY").round_to(0, round_half_up()),
    Money::of(5, "JPY"),
  )
}

///|
test "format Int boundaries" {
  assert_eq(Money::of(2147483647, "CNY").format(), "21,474,836.47")
  assert_eq(Money::of(-2147483648, "CNY").format(), "-21,474,836.48")
  assert_eq(Money::of(-2147483648, "JPY").format(), "-2,147,483,648")
}

///|
test "panic add rejects mismatched currencies" {
  ignore(Money::of(1, "CNY").add(Money::of(1, "USD")))
}

///|
test "panic sub rejects mismatched currencies" {
  ignore(Money::of(1, "CNY").sub(Money::of(1, "JPY")))
}

///|
test "panic constructor rejects unsupported currency" {
  ignore(Money::of(1, "ZZZ"))
}

///|
test "panic constructor rejects malformed currency" {
  ignore(Money::zero("cny"))
}

///|
test "panic round_to rejects negative decimals" {
  ignore(Money::of(1, "CNY").round_to(-1, round_half_up()))
}

///|
test "panic round_to rejects excessive decimals" {
  ignore(Money::of(1, "JPY").round_to(1, round_half_up()))
}

///|
test "panic round_to rejects overflow" {
  ignore(Money::of(2147483647, "CNY").round_to(0, round_up()))
}

///|
test "panic round_to rejects negative overflow" {
  ignore(Money::of(-2147483648, "CNY").round_to(0, round_up()))
}

///|
test "panic add rejects overflow" {
  ignore(Money::of(2147483647, "CNY").add(Money::of(1, "CNY")))
}

///|
test "panic sub rejects overflow" {
  ignore(Money::of(-2147483648, "CNY").sub(Money::of(1, "CNY")))
}

///|
test "panic neg rejects overflow" {
  ignore(Money::of(-2147483648, "CNY").neg())
}

///|
test "panic scale rejects overflow" {
  ignore(Money::of(2147483647, "CNY").scale(2))
}

///|
test "format with grouping and fraction" {
  assert_eq(Money::of(1234567, "CNY").format(), "12,345.67")
  assert_eq(Money::of(-12345, "CNY").format(), "-123.45")
  assert_eq(Money::of(5, "CNY").format(), "0.05")
  assert_eq(Money::of(0, "CNY").format(), "0.00")
  assert_eq(Money::of(100000000, "CNY").format(), "1,000,000.00")
}
