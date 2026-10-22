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
  assert_true(approx(@ratio.current_ratio(1000.0, 500.0), 2.0, 1.0e-9))
  assert_true(approx(@ratio.quick_ratio(1000.0, 300.0, 500.0), 1.4, 1.0e-9))
}

///|
test "solvency ratios" {
  assert_true(approx(@ratio.debt_to_assets(400.0, 1000.0), 0.4, 1.0e-9))
  assert_true(approx(@ratio.interest_coverage(100.0, 20.0), 5.0, 1.0e-9))
}

///|
test "profitability ratios" {
  assert_true(approx(@ratio.gross_margin(400.0, 1000.0), 0.4, 1.0e-9))
  assert_true(approx(@ratio.net_margin(100.0, 1000.0), 0.1, 1.0e-9))
  assert_true(approx(@ratio.return_on_equity(100.0, 500.0), 0.2, 1.0e-9))
  assert_true(approx(@ratio.return_on_assets(100.0, 1000.0), 0.1, 1.0e-9))
}

///|
test "efficiency and valuation ratios" {
  assert_true(approx(@ratio.asset_turnover(1000.0, 2000.0), 0.5, 1.0e-9))
  assert_true(approx(@ratio.inventory_turnover(600.0, 200.0), 3.0, 1.0e-9))
  assert_true(approx(@ratio.price_earnings_ratio(50.0, 5.0), 10.0, 1.0e-9))
  assert_true(approx(@ratio.price_to_book(50.0, 10.0), 5.0, 1.0e-9))
  assert_true(approx(@ratio.earnings_per_share(100.0, 20.0), 5.0, 1.0e-9))
}

///|
test "zero denominator returns None" {
  assert_true(@ratio.current_ratio(1000.0, 0.0) == None)
  assert_true(@ratio.debt_to_assets(400.0, 0.0) == None)
  assert_true(@ratio.return_on_equity(100.0, 0.0) == None)
  assert_true(@ratio.price_earnings_ratio(50.0, 0.0) == None)
  assert_true(@ratio.earnings_per_share(100.0, 0.0) == None)
}

///|
test "non finite operands return None" {
  assert_true(@ratio.current_ratio(1000.0, @double.infinity) == None)
  assert_true(@ratio.current_ratio(@double.not_a_number, 500.0) == None)
  assert_true(@ratio.quick_ratio(@double.infinity, 100.0, 500.0) == None)
  assert_true(@ratio.earnings_per_share(100.0, @double.infinity) == None)
}
