// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// 浮点近似比较，容忍双精度误差。
fn approx(actual : Double?, expected : Double, eps : Double) -> Bool {
  match actual {
    Some(value) => (value - expected).abs() < eps
    None => false
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
  match internal_rate_of_return(cf) {
    Some(irr) => {
      assert_true(irr > 0.0)
      assert_true(irr < 0.2)
      assert_true(approx(net_present_value(irr, cf), 0.0, 1.0e-6))
    }
    None => fail("expected a unique IRR")
  }
}

///|
test "IRR no solution, multiple roots, and interval boundaries" {
  assert_true(internal_rate_of_return([-100.0, -10.0]) == None)
  assert_true(internal_rate_of_return([0.0, 0.0]) == None)
  // These cash flows have roots at 10% and 20%.
  assert_true(internal_rate_of_return([-100.0, 230.0, -132.0]) == None)
  let cf = [-100.0, 110.0]
  assert_true(approx(internal_rate_of_return(cf), 0.1, 1.0e-9))
  assert_true(
    approx(internal_rate_of_return_in_range(cf, 0.1, 0.5), 0.1, 1.0e-9),
  )
  assert_true(internal_rate_of_return_in_range(cf, 0.2, 0.5) == None)
  assert_true(internal_rate_of_return_in_range(cf, -1.0, 0.5) == None)
  assert_true(internal_rate_of_return_in_range(cf, 0.5, 0.5) == None)
  assert_true(internal_rate_of_return_in_range(cf, 0.5, 0.1) == None)
  assert_true(approx(internal_rate_of_return([-100.0, 50.0]), -0.5, 1.0e-9))
  assert_true(approx(internal_rate_of_return([100.0, -110.0]), 0.1, 1.0e-9))
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
test "unrecovered and boundary payback" {
  assert_true(payback_period([]) == None)
  assert_true(payback_period([-100.0, 20.0, 30.0]) == None)
  assert_true(discounted_payback_period(0.1, [-100.0, 50.0, 50.0]) == None)
  assert_true(approx(payback_period([0.0]), 0.0, 1.0e-9))
  assert_true(approx(discounted_payback_period(0.1, [10.0]), 0.0, 1.0e-9))
  assert_true(
    approx(discounted_payback_period(-0.5, [-100.0, 50.0]), 1.0, 1.0e-9),
  )
}

///|
test "invalid rates, cash flows, and non-finite results" {
  assert_true(net_present_value(-1.0, [-100.0, 110.0]) == None)
  assert_true(net_present_value(@double.not_a_number, [-100.0, 110.0]) == None)
  assert_true(net_present_value(0.1, []) == None)
  assert_true(net_present_value(0.1, [-100.0, @double.infinity]) == None)
  assert_true(internal_rate_of_return([-100.0, @double.not_a_number]) == None)
  assert_true(
    internal_rate_of_return_in_range([-100.0, 110.0], 0.0, @double.infinity) ==
    None,
  )
  assert_true(payback_period([-100.0, @double.infinity]) == None)
  assert_true(discounted_payback_period(-1.0, [-100.0, 110.0]) == None)
  assert_true(profitability_index(0.1, [0.0, 110.0]) == None)
  assert_true(profitability_index(-1.0, [-100.0, 110.0]) == None)
  assert_true(net_present_value(0.0, [1.0e308, 1.0e308]) == None)
  assert_true(payback_period([-1.0e308, -1.0e308]) == None)
}

///|
test "profitability index" {
  let cf = [-1000.0, 300.0, 400.0, 500.0]
  assert_true(approx(profitability_index(0.10, cf), 0.9789631855, 1.0e-6))
}
