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
test "net present value" {
  let cf = [-1000.0, 300.0, 400.0, 500.0]
  assert_true(approx(net_present_value(0.10, cf), -21.0368145, 1.0e-6))
  assert_true(approx(net_present_value(0.0, cf), 200.0, 1.0e-9))
}

///|
test "internal rate of return zeroes npv" {
  let cf = [-1000.0, 300.0, 400.0, 500.0]
  let irr = internal_rate_of_return(cf)
  assert_true(irr > 0.0)
  assert_true(irr < 0.2)
  assert_true(approx(net_present_value(irr, cf), 0.0, 1.0e-6))
}

///|
test "payback period" {
  let cf = [-1000.0, 500.0, 500.0, 500.0]
  assert_true(approx(payback_period(cf), 2.0, 1.0e-9))
  let cf2 = [-1000.0, 300.0, 400.0, 500.0]
  assert_true(approx(payback_period(cf2), 2.6, 1.0e-9))
}

///|
test "discounted payback period" {
  let cf = [-1000.0, 500.0, 500.0, 500.0]
  assert_true(approx(discounted_payback_period(0.0, cf), 2.0, 1.0e-9))
}

///|
test "profitability index" {
  let cf = [-1000.0, 300.0, 400.0, 500.0]
  assert_true(approx(profitability_index(0.10, cf), 0.9789631855, 1.0e-6))
}
