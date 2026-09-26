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
test "straight line depreciation" {
  assert_true(approx(straight_line_depreciation(10000.0, 1000.0, 5), 1800.0, 1.0e-9))
}

///|
test "double declining balance depreciation" {
  // 成本 10000，残值 1000，5 年：4000 / 2400 / 1440 / 580 / 580
  assert_true(
    approx(double_declining_balance_depreciation(10000.0, 1000.0, 5, 1), 4000.0, 1.0e-9),
  )
  assert_true(
    approx(double_declining_balance_depreciation(10000.0, 1000.0, 5, 2), 2400.0, 1.0e-9),
  )
  assert_true(
    approx(double_declining_balance_depreciation(10000.0, 1000.0, 5, 5), 580.0, 1.0e-9),
  )
}

///|
test "sum of years digits depreciation" {
  // 可折旧额 9000，年数总和 15：第 1 年 3000，第 3 年 1800，第 5 年 600
  assert_true(
    approx(sum_of_years_digits_depreciation(10000.0, 1000.0, 5, 1), 3000.0, 1.0e-9),
  )
  assert_true(
    approx(sum_of_years_digits_depreciation(10000.0, 1000.0, 5, 3), 1800.0, 1.0e-9),
  )
  assert_true(
    approx(sum_of_years_digits_depreciation(10000.0, 1000.0, 5, 5), 600.0, 1.0e-9),
  )
}

///|
test "units of production depreciation" {
  // 成本 10000，残值 1000，总工作量 10000，本年 2000
  assert_true(
    approx(units_of_production_depreciation(10000.0, 1000.0, 10000.0, 2000.0), 1800.0, 1.0e-9),
  )
}
