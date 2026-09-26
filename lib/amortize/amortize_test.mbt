// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// 浮点近似比较，容忍双精度误差。
fn approx(a : Double, b : Double, eps : Double) -> Bool {
  let d = a - b
  if d < 0.0 {
    -d < eps
  } else {
    d < eps
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
  let s = equal_installment_schedule(10000.0, 0.01, 12)
  assert_eq(s.length(), 12)
  assert_true(approx(s[0].interest, 100.0, 1.0e-9))
  assert_true(approx(s[11].balance, 0.0, 1.0e-6))
  let mut sum = 0.0
  let mut i = 0
  while i < s.length() {
    sum = sum + s[i].principal
    i = i + 1
  }
  assert_true(approx(sum, 10000.0, 1.0e-6))
}

///|
test "equal principal schedule" {
  let s = equal_principal_schedule(10000.0, 0.01, 12)
  assert_eq(s.length(), 12)
  assert_true(approx(s[0].principal, 833.3333333, 1.0e-6))
  assert_true(approx(s[0].interest, 100.0, 1.0e-9))
  assert_true(approx(s[11].balance, 0.0, 1.0e-6))
}

///|
test "total interest" {
  assert_true(
    approx(total_interest_equal_installment(10000.0, 0.01, 12), 661.8546414, 1.0e-6),
  )
  assert_true(approx(total_interest_equal_principal(10000.0, 0.01, 12), 650.0, 1.0e-9))
}
