// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// 对 Option 值做浮点近似比较。
fn approx(value : Double?, expected : Double, eps : Double) -> Bool {
  match value {
    Some(actual) => (actual - expected).abs() < eps
    None => false
  }
}

///|
test "lookup currency metadata" {
  match lookup("CNY") {
    Some(c) => {
      assert_eq(c.code, "CNY")
      assert_eq(c.decimals, 2)
    }
    None => fail("expected CNY")
  }
  match lookup("JPY") {
    Some(c) => assert_eq(c.decimals, 0)
    None => fail("expected JPY")
  }
  assert_true(lookup("XXX") == None)
}

///|
test "convert same decimals" {
  let cny = @money.Money::of(10000, "CNY") // 100.00 元
  match convert(cny, "USD", 0.14) {
    Some(usd) => {
      assert_eq(usd.currency(), "USD")
      assert_eq(usd.minor(), 1400) // 14.00 美元
    }
    None => fail("expected converted amount")
  }
}

///|
test "convert across decimals" {
  let jpy = @money.Money::of(100, "JPY") // 100 日元（0 位小数）
  match convert(jpy, "USD", 0.007) {
    Some(usd) => assert_eq(usd.minor(), 70) // 0.70 美元
    None => fail("expected converted amount")
  }
}

///|
test "cross rate" {
  assert_true(approx(cross_rate(0.14, 1.1), 0.154, 1.0e-9))
}

///|
test "invalid conversion returns None" {
  let cny = @money.Money::of(10000, "CNY")
  assert_true(convert(cny, "USD", 0.0) == None)
  assert_true(convert(cny, "USD", -1.0) == None)
  assert_true(convert(cny, "USD", @double.not_a_number) == None)
  assert_true(convert(cny, "XXX", 0.14) == None)
  assert_true(convert(cny, "USD", @double.infinity) == None)
  assert_true(convert(cny, "USD", 1.0e20) == None)
  assert_true(convert(@money.Money::of(1, "CNY"), "USD", 2147483647.5) == None)
  assert_true(convert(@money.Money::of(-1, "CNY"), "USD", 2147483648.5) == None)
}

///|
test "conversion keeps representable negative Int boundary" {
  let amount = @money.Money::of(-1, "CNY")
  match convert(amount, "USD", 2147483648.0) {
    Some(value) => assert_eq(value.minor(), -2147483648)
    None => fail("expected Int minimum")
  }
}
