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
test "equal installment payment" {
  // 本金 10000，月利率 1%，12 期：月供约 888.49
  assert_true(approx(equal_installment_payment(10000.0, 0.01, 12), 888.4878869, 1.0e-6))
  // 零利率时即为等额分摊
  assert_true(approx(equal_installment_payment(10000.0, 0.0, 12), 833.3333333, 1.0e-6))
}

///|
test "equal installment schedule" {
  match equal_installment_schedule(10000.0, 0.01, 12) {
    Some(s) => {
      assert_eq(s.length(), 12)
      assert_true((s[0].interest - 100.0).abs() < 1.0e-9)
      assert_true((s[11].balance - 0.0).abs() < 1.0e-6)
      let mut sum = 0.0
      let mut i = 0
      while i < s.length() {
        sum = sum + s[i].principal
        i = i + 1
      }
      assert_true((sum - 10000.0).abs() < 1.0e-6)
    }
    None => fail("expected a schedule")
  }
}

///|
test "equal principal schedule" {
  match equal_principal_schedule(10000.0, 0.01, 12) {
    Some(s) => {
      assert_eq(s.length(), 12)
      assert_true((s[0].principal - 833.3333333).abs() < 1.0e-6)
      assert_true((s[0].interest - 100.0).abs() < 1.0e-9)
      assert_true((s[11].balance - 0.0).abs() < 1.0e-6)
    }
    None => fail("expected a schedule")
  }
}

///|
test "total interest" {
  assert_true(
    approx(total_interest_equal_installment(10000.0, 0.01, 12), 661.8546414, 1.0e-6),
  )
  assert_true(approx(total_interest_equal_principal(10000.0, 0.01, 12), 650.0, 1.0e-9))
}

///|
test "invalid inputs return None" {
  assert_true(equal_installment_payment(10000.0, 0.01, 0) == None)
  assert_true(equal_installment_payment(10000.0, 0.01, -1) == None)
  assert_true(equal_installment_schedule(10000.0, -1.0, 12) == None)
  assert_true(equal_principal_schedule(10000.0, 0.01, 0) == None)
  assert_true(total_interest_equal_installment(10000.0, 0.01, 0) == None)
  assert_true(total_interest_equal_principal(10000.0, 0.01, 0) == None)
}

