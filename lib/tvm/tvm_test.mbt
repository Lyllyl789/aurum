// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
fn approx(value : Double?, expected : Double, eps : Double) -> Bool {
  match value {
    Some(actual) => (actual - expected).abs() < eps
    None => false
  }
}

///|
test "single cash flows, negative rates, and zero periods" {
  assert_true(approx(future_value(1000.0, 0.05, 2), 1102.5, 1.0e-9))
  assert_true(approx(present_value(1102.5, 0.05, 2), 1000.0, 1.0e-9))
  assert_true(approx(future_value(1000.0, 0.0, 5), 1000.0, 1.0e-9))
  assert_true(approx(future_value(1000.0, -0.1, 2), 810.0, 1.0e-9))
  assert_true(approx(present_value(810.0, -0.1, 2), 1000.0, 1.0e-9))
  assert_true(approx(future_value(1000.0, 0.05, 0), 1000.0, 1.0e-9))
}

///|
test "ordinary and due annuities" {
  assert_true(approx(future_value_annuity(1000.0, 0.05, 3), 3152.5, 1.0e-9))
  assert_true(
    approx(present_value_annuity(1000.0, 0.05, 3), 2723.248029370486, 1.0e-9),
  )
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
  assert_true(approx(future_value_annuity(1000.0, 0.0, 3), 3000.0, 1.0e-9))
  assert_true(approx(present_value_annuity(1000.0, 0.0, 3), 3000.0, 1.0e-9))
  assert_true(approx(future_value_annuity(1000.0, -0.1, 2), 1900.0, 1.0e-9))
  assert_true(
    approx(present_value_annuity(1000.0, -0.1, 2), 2345.679012345679, 1.0e-9),
  )
  assert_true(approx(future_value_annuity_due(1000.0, 0.0, 0), 0.0, 1.0e-9))
  assert_true(approx(present_value_annuity_due(1000.0, 0.0, 0), 0.0, 1.0e-9))
  assert_true(
    approx(future_value_annuity(1000.0, 1.0e-12, 3), 3000.000000003, 1.0e-8),
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

///|
test "invalid rates and periods return None" {
  assert_true(future_value(100.0, -1.0, 2) == None)
  assert_true(present_value(100.0, -1.1, 2) == None)
  assert_true(future_value(100.0, 0.05, -1) == None)
  assert_true(present_value(100.0, 0.05, -1) == None)
  assert_true(future_value_annuity(100.0, -1.0, 2) == None)
  assert_true(present_value_annuity(100.0, 0.05, -1) == None)
  assert_true(future_value_annuity_due(100.0, 0.05, -1) == None)
  assert_true(present_value_annuity_due(100.0, -1.0, 2) == None)
  assert_true(present_value_perpetuity(100.0, 0.0) == None)
  assert_true(present_value_perpetuity(100.0, -0.1) == None)
  assert_true(present_value_growing_perpetuity(100.0, 0.05, 0.05) == None)
  assert_true(present_value_growing_perpetuity(100.0, 0.05, -1.0) == None)
}

///|
test "non-finite inputs and outputs return None" {
  assert_true(future_value(@double.not_a_number, 0.05, 2) == None)
  assert_true(present_value(100.0, @double.infinity, 2) == None)
  assert_true(future_value_annuity(@double.infinity, 0.05, 2) == None)
  assert_true(present_value_annuity(100.0, @double.not_a_number, 2) == None)
  assert_true(present_value_perpetuity(@double.infinity, 0.05) == None)
  assert_true(
    present_value_growing_perpetuity(100.0, 0.1, @double.not_a_number) == None,
  )
  assert_true(future_value(1.0e308, 1.0, 1024) == None)
  assert_true(present_value(1.0e308, -0.999, 1024) == None)
  assert_true(future_value_annuity(1.0e308, 1.0, 1024) == None)
  assert_true(present_value_perpetuity(1.0e308, 1.0e-308) == None)
}
