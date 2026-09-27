// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
test "CNY conversion funds a one period USD loan" {
  // 100.00 CNY × caller-supplied 0.14 USD/CNY = 14.00 USD.
  let cny = @money.Money::of(10000, "CNY")
  let usd = match @currency.convert(cny, "USD", 0.14) {
    Some(value) => value
    None => fail("expected USD amount")
  }
  assert_eq(usd.minor(), 1400)
  assert_eq(usd.format(), "14.00")

  // One period at 5%: 14.00 principal + 0.70 interest = 14.70.
  let principal = usd.minor().to_double() / 100.0
  match @amortize.equal_installment_schedule(principal, 0.05, 1) {
    Some(schedule) => {
      assert_eq(schedule.length(), 1)
      assert_true((schedule[0].principal - 14.0).abs() < 1.0e-9)
      assert_true((schedule[0].interest - 0.7).abs() < 1.0e-9)
      assert_true((schedule[0].balance - 0.0).abs() < 1.0e-9)
    }
    None => fail("expected repayment schedule")
  }
  match @amortize.equal_installment_payment(principal, 0.05, 1) {
    Some(payment) => {
      assert_true((payment - 14.7).abs() < 1.0e-9)
      assert_eq(
        @money.Money::of((payment * 100.0 + 0.5).to_int(), "USD").minor(),
        1470,
      )
    }
    None => fail("expected repayment")
  }

  assert_true(@currency.convert(cny, "USD", 0.0) == None)
  assert_true(@amortize.equal_installment_payment(principal, -1.0, 1) == None)
}
