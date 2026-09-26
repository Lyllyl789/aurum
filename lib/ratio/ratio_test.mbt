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
test "liquidity ratios" {
  assert_true(approx(current_ratio(1000.0, 500.0), 2.0, 1.0e-9))
  assert_true(approx(quick_ratio(1000.0, 300.0, 500.0), 1.4, 1.0e-9))
}

///|
test "solvency ratios" {
  assert_true(approx(debt_to_assets(400.0, 1000.0), 0.4, 1.0e-9))
  assert_true(approx(interest_coverage(100.0, 20.0), 5.0, 1.0e-9))
}

///|
test "profitability ratios" {
  assert_true(approx(gross_margin(400.0, 1000.0), 0.4, 1.0e-9))
  assert_true(approx(net_margin(100.0, 1000.0), 0.1, 1.0e-9))
  assert_true(approx(return_on_equity(100.0, 500.0), 0.2, 1.0e-9))
  assert_true(approx(return_on_assets(100.0, 1000.0), 0.1, 1.0e-9))
}

///|
test "efficiency and valuation ratios" {
  assert_true(approx(asset_turnover(1000.0, 2000.0), 0.5, 1.0e-9))
  assert_true(approx(inventory_turnover(600.0, 200.0), 3.0, 1.0e-9))
  assert_true(approx(price_earnings_ratio(50.0, 5.0), 10.0, 1.0e-9))
  assert_true(approx(price_to_book(50.0, 10.0), 5.0, 1.0e-9))
  assert_true(approx(earnings_per_share(100.0, 20.0), 5.0, 1.0e-9))
}

///|
test "zero denominator returns None" {
  assert_true(current_ratio(1000.0, 0.0) == None)
  assert_true(debt_to_assets(400.0, 0.0) == None)
  assert_true(return_on_equity(100.0, 0.0) == None)
  assert_true(price_earnings_ratio(50.0, 0.0) == None)
  assert_true(earnings_per_share(100.0, 0.0) == None)
}
