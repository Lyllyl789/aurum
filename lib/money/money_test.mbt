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
test "fallible constructor and exact decimal parsing" {
  assert_eq(Money::try_of(25, "CNY"), Some(Money::of(25, "CNY")))
  assert_eq(Money::try_of(25, "XXX"), None)
  assert_eq(Money::parse("123.45", "CNY"), Some(Money::of(12345, "CNY")))
  assert_eq(Money::parse("-0.005", "KWD"), Some(Money::of(-5, "KWD")))
  assert_eq(Money::parse("17.000", "JPY"), Some(Money::of(17, "JPY")))
  assert_eq(
    Money::parse("21474836.47", "CNY"),
    Some(Money::of(2147483647, "CNY")),
  )
  assert_eq(
    Money::parse("-21474836.48", "CNY"),
    Some(Money::of(-2147483648, "CNY")),
  )
  assert_eq(Money::parse("21474836.48", "CNY"), None)
  assert_eq(Money::parse("21474836.48", "USD"), None)
  assert_eq(Money::parse("1.001", "CNY"), None)
  assert_eq(Money::parse(" 1.00", "CNY"), None)
  assert_eq(Money::parse("1,000.00", "CNY"), None)
  assert_eq(Money::parse("1e2", "CNY"), None)
  assert_eq(Money::parse(".50", "CNY"), None)
  assert_eq(Money::parse("1.", "CNY"), None)
  assert_eq(Money::parse("--1", "CNY"), None)
  assert_eq(Money::parse("1.0", "XXX"), None)
}

///|
test "decimal parsing rounds only when explicitly requested" {
  assert_eq(
    Money::parse_rounded("1.235", "CNY", round_half_up()),
    Some(Money::of(124, "CNY")),
  )
  assert_eq(
    Money::parse_rounded("-1.235", "CNY", round_half_even()),
    Some(Money::of(-124, "CNY")),
  )
  assert_eq(
    Money::parse_rounded("1.245", "CNY", round_half_even()),
    Some(Money::of(124, "CNY")),
  )
  assert_eq(
    Money::parse_rounded("1.230", "CNY", round_up()),
    Some(Money::of(123, "CNY")),
  )
  assert_eq(
    Money::parse_rounded("-1.231", "CNY", round_up()),
    Some(Money::of(-124, "CNY")),
  )
  assert_eq(
    Money::parse_rounded("-1.239", "CNY", round_down()),
    Some(Money::of(-123, "CNY")),
  )
  assert_eq(Money::parse_rounded("21474836.485", "CNY", round_half_up()), None)
  assert_eq(Money::parse_rounded("-21474836.485", "CNY", round_half_up()), None)
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
test "fallible arithmetic and aggregation report errors as None" {
  let a = Money::of(125, "CNY")
  let b = Money::of(25, "CNY")
  assert_eq(a.try_add(b), Some(Money::of(150, "CNY")))
  assert_eq(a.try_sub(b), Some(Money::of(100, "CNY")))
  assert_eq(a.try_neg(), Some(Money::of(-125, "CNY")))
  assert_eq(Money::of(-125, "CNY").abs(), Some(a))
  assert_eq(a.try_scale(2), Some(Money::of(250, "CNY")))
  assert_eq(a.try_compare(b), Some(1))
  assert_eq(b.try_compare(a), Some(-1))
  assert_eq(a.try_compare(a), Some(0))
  assert_eq(Money::sum([a, b], "CNY"), Some(Money::of(150, "CNY")))
  assert_eq(Money::sum([], "JPY"), Some(Money::zero("JPY")))
  assert_eq(a.try_add(Money::of(1, "USD")), None)
  assert_eq(a.try_sub(Money::of(1, "USD")), None)
  assert_eq(Money::of(2147483647, "CNY").try_add(Money::of(1, "CNY")), None)
  assert_eq(Money::of(-2147483648, "CNY").try_sub(Money::of(1, "CNY")), None)
  assert_eq(Money::of(2147483647, "CNY").try_scale(2), None)
  assert_eq(a.try_compare(Money::of(1, "USD")), None)
  assert_eq(Money::sum([a], "USD"), None)
  assert_eq(
    Money::sum([Money::of(2147483647, "CNY"), Money::of(1, "CNY")], "CNY"),
    None,
  )
  assert_eq(Money::of(-2147483648, "JPY").try_neg(), None)
  assert_eq(Money::of(-2147483648, "JPY").abs(), None)
  assert_eq(a.to_major_double(), 1.25)
  assert_eq(a.to_decimal_string(), "1.25")
  assert_eq(a.ratio_to(Money::of(500, "CNY")), Some(0.25))
  assert_eq(a.ratio_to(Money::zero("CNY")), None)
  assert_eq(a.ratio_to(Money::of(500, "USD")), None)
}

///|
test "decimal string output round trips across currency scales and bounds" {
  let amounts = [
    Money::of(5, "CNY"),
    Money::of(-12345, "CNY"),
    Money::of(-2147483648, "CNY"),
    Money::of(1234, "JPY"),
    Money::of(-5, "KWD"),
  ]
  for amount in amounts {
    assert_eq(
      Money::parse(amount.to_decimal_string(), amount.currency()),
      Some(amount),
    )
  }
}

///|
test "ratio scaling uses integer arithmetic and explicit rounding" {
  let one_dollar = Money::of(100, "USD")
  assert_eq(
    one_dollar.scale_ratio(1, 3, round_half_up()),
    Some(Money::of(33, "USD")),
  )
  assert_eq(
    one_dollar.scale_ratio(1, 3, round_up()),
    Some(Money::of(34, "USD")),
  )
  assert_eq(
    Money::of(-100, "USD").scale_ratio(1, 3, round_half_up()),
    Some(Money::of(-33, "USD")),
  )
  assert_eq(
    Money::of(100, "USD").scale_ratio(-1, 3, round_half_up()),
    Some(Money::of(-33, "USD")),
  )
  assert_eq(Money::of(100, "USD").scale_ratio(1, 0, round_half_up()), None)
  assert_eq(Money::of(100, "USD").scale_ratio(1, -2, round_half_up()), None)
  assert_eq(
    Money::of(2147483647, "JPY").scale_ratio(2, 1, round_half_up()),
    None,
  )
}

///|
test "equal allocation preserves total for positive and negative amounts" {
  match Money::of(100, "USD").allocate_equal(3) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(34, "USD"),
        Money::of(33, "USD"),
        Money::of(33, "USD"),
      ])
    None => fail("expected split")
  }
  match Money::of(-100, "USD").allocate_equal(3) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(-34, "USD"),
        Money::of(-33, "USD"),
        Money::of(-33, "USD"),
      ])
    None => fail("expected negative split")
  }
  assert_eq(Money::of(1, "JPY").allocate_equal(0), None)
  assert_eq(Money::of(1, "JPY").allocate_equal(-2), None)
}

///|
test "weighted allocation uses largest remainders and stable ties" {
  match Money::of(10, "USD").allocate_by_weights([1, 1, 1]) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(4, "USD"),
        Money::of(3, "USD"),
        Money::of(3, "USD"),
      ])
    None => fail("expected weighted split")
  }
  match Money::of(100, "USD").allocate_by_weights([1, 2, 3]) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(17, "USD"),
        Money::of(33, "USD"),
        Money::of(50, "USD"),
      ])
    None => fail("expected proportional split")
  }
  match Money::of(2, "JPY").allocate_by_weights([1, 2, 4]) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(0, "JPY"),
        Money::of(1, "JPY"),
        Money::of(1, "JPY"),
      ])
    None => fail("expected remainder-ranked split")
  }
  match Money::of(-1, "JPY").allocate_by_weights([1, 1, 1]) {
    Some(parts) =>
      assert_eq(parts, [
        Money::of(-1, "JPY"),
        Money::of(0, "JPY"),
        Money::of(0, "JPY"),
      ])
    None => fail("expected negative weighted split")
  }
}

///|
test "weighted allocation rejects missing, zero, and negative weights" {
  assert_eq(Money::of(1, "USD").allocate_by_weights([]), None)
  assert_eq(Money::of(1, "USD").allocate_by_weights([0, 0]), None)
  assert_eq(Money::of(1, "USD").allocate_by_weights([1, -1]), None)
  assert_eq(
    Money::of(0, "USD").allocate_by_weights([0, 5]),
    Some([Money::of(0, "USD"), Money::of(0, "USD")]),
  )
  match
    Money::of(2147483647, "JPY").allocate_by_weights([2147483647, 2147483647]) {
    Some(parts) => {
      assert_eq(parts[0].minor() + parts[1].minor(), 2147483647)
      assert_true(parts[0].minor() >= parts[1].minor())
    }
    None => fail("expected Int64-safe weighted split")
  }
}

///|
test "weighted allocation conserves small signed amounts across weight grids" {
  let mut amount = -20
  while amount <= 20 {
    let mut first_weight = 0
    while first_weight <= 4 {
      let mut second_weight = 0
      while second_weight <= 4 {
        let mut third_weight = 0
        while third_weight <= 4 {
          let weights = [first_weight, second_weight, third_weight]
          if first_weight + second_weight + third_weight > 0 {
            match Money::of(amount, "JPY").allocate_by_weights(weights) {
              Some(parts) => {
                let total = parts[0].minor() +
                  parts[1].minor() +
                  parts[2].minor()
                assert_eq(total, amount)
              }
              None => fail("valid weights must conserve the amount")
            }
          }
          third_weight = third_weight + 1
        }
        second_weight = second_weight + 1
      }
      first_weight = first_weight + 1
    }
    amount = amount + 1
  }
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
test "round_div does not overflow when comparing large remainders" {
  assert_eq(round_div(1073741824, 2147483647, round_half_up()), 1)
  assert_eq(round_div(-1073741824, 2147483647, round_half_up()), -1)
  assert_eq(round_div(1073741824, 2147483647, round_half_even()), 1)
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
