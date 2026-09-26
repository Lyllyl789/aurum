// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// 对 Option 值做浮点近似比较。
fn approx_option(value : Double?, expected : Double, eps : Double) -> Bool {
  match value {
    Some(actual) => (actual - expected).abs() < eps
    None => false
  }
}

///|
/// 浮点近似比较。
fn approx(a : Double, b : Double, eps : Double) -> Bool {
  (a - b).abs() < eps
}

///|
test "bond price at par and premium" {
  // 票息率等于收益率：平价
  assert_true(approx_option(price(50.0, 1000.0, 0.05, 10), 1000.0, 1.0e-6))
  // 票息率 6% 高于收益率 5%：溢价
  assert_true(approx_option(price(60.0, 1000.0, 0.05, 10), 1077.21734929, 1.0e-6))
}

///|
test "yield to maturity" {
  match yield_to_maturity(1000.0, 50.0, 1000.0, 10) {
    Some(ytm) => {
      assert_true(approx(ytm, 0.05, 1.0e-6))
      assert_true(approx_option(price(50.0, 1000.0, ytm, 10), 1000.0, 1.0e-6))
    }
    None => fail("expected a yield to maturity")
  }
}

///|
test "duration" {
  // 零息债券麦考利久期等于期数，修正久期再除以 (1+y)
  assert_true(approx_option(macaulay_duration(0.0, 1000.0, 0.05, 10), 10.0, 1.0e-6))
  assert_true(approx_option(modified_duration(0.0, 1000.0, 0.05, 10), 9.5238095238, 1.0e-6))
}

///|
test "convexity" {
  // 零息债券凸性 = n(n+1)/(1+y)^2
  assert_true(approx_option(convexity(0.0, 1000.0, 0.05, 10), 99.77324263, 1.0e-6))
}

///|
test "invalid inputs return None" {
  assert_true(price(50.0, 1000.0, 0.05, 0) == None)
  assert_true(price(50.0, 1000.0, 0.05, -1) == None)
  assert_true(yield_to_maturity(1000.0, 50.0, 1000.0, 0) == None)
  assert_true(macaulay_duration(0.0, 1000.0, 0.05, 0) == None)
  assert_true(convexity(0.0, 1000.0, @double.not_a_number, 10) == None)
}
