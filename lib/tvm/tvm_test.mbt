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
test "single cash flow future and present value" {
  assert_true(approx(future_value(1000.0, 0.05, 2), 1102.5, 1.0e-9))
  assert_true(approx(present_value(1102.5, 0.05, 2), 1000.0, 1.0e-9))
  assert_true(approx(future_value(1000.0, 0.0, 5), 1000.0, 1.0e-9))
}

///|
test "ordinary annuity future value" {
  assert_true(approx(future_value_annuity(1000.0, 0.05, 3), 3152.5, 1.0e-9))
  assert_true(approx(future_value_annuity(1000.0, 0.0, 3), 3000.0, 1.0e-9))
}

///|
test "ordinary annuity present value" {
  assert_true(
    approx(present_value_annuity(1000.0, 0.05, 3), 2723.248029370486, 1.0e-9),
  )
  assert_true(approx(present_value_annuity(1000.0, 0.0, 3), 3000.0, 1.0e-9))
}

///|
test "annuity due future and present value" {
  assert_true(
    approx(future_value_annuity_due(1000.0, 0.05, 3), 3310.125, 1.0e-9),
  )
  assert_true(
    approx(
      present_value_annuity_due(1000.0, 0.05, 3),
      2859.4104308390103,
      1.0e-9,
    ),
  )
}

///|
test "perpetuities" {
  assert_true(approx(present_value_perpetuity(1000.0, 0.05), 20000.0, 1.0e-9))
  assert_true(
    approx(
      present_value_growing_perpetuity(1000.0, 0.10, 0.04),
      16666.666666666668,
      1.0e-9,
    ),
  )
}
