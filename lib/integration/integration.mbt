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

///|
test "review acceptance examples for core calculations" {
  let cents = @money.Money::of(10, "CNY").add(@money.Money::of(20, "CNY"))
  assert_eq(cents.minor(), 30)
  assert_eq(cents.format(), "0.30")

  match @tvm.future_value(1000.0, 0.05, 2) {
    Some(value) => assert_true((value - 1102.5).abs() < 1.0e-9)
    None => fail("expected finite future value")
  }
  match @capital.net_present_value(0.10, [-1000.0, 300.0, 400.0, 500.0]) {
    Some(value) => assert_true((value - -21.0368145).abs() < 1.0e-6)
    None => fail("expected finite NPV")
  }
  match @capital.internal_rate_of_return([-100.0, 110.0]) {
    Some(value) => assert_true((value - 0.1).abs() < 1.0e-9)
    None => fail("expected IRR for a single sign change")
  }
  match @amortize.equal_installment_payment(10000.0, 0.01, 12) {
    Some(value) => assert_true((value - 888.4878869).abs() < 1.0e-6)
    None => fail("expected finite installment payment")
  }
  assert_true(
    @capital.net_present_value(0.1, [-100.0, @double.infinity]) == None,
  )
}

///|
test "parsed money, exact weighted split, and rounded loan plan compose" {
  let source = match @money.Money::parse("100.00", "CNY") {
    Some(value) => value
    None => fail("expected exact decimal parse")
  }
  let shares = match source.allocate_by_weights([1, 2, 3]) {
    Some(value) => value
    None => fail("expected weighted allocation")
  }
  assert_eq(shares[0].minor(), 1667)
  assert_eq(shares[1].minor(), 3333)
  assert_eq(shares[2].minor(), 5000)
  assert_eq(
    shares[0].minor() + shares[1].minor() + shares[2].minor(),
    source.minor(),
  )

  let loan = @money.Money::of(1000000, "CNY")
  let rows = match
    @amortize.equal_installment_money_schedule(
      loan,
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => fail("expected cent-rounded loan plan")
  }
  let summary = match @amortize.summarize_money_schedule(rows) {
    Some(value) => value
    None => fail("expected reconciled loan summary")
  }
  assert_eq(summary.principal, loan)
  assert_eq(summary.periods, 12)
  assert_eq(summary.ending_balance, @money.Money::zero("CNY"))
  assert_true(summary.interest.minor() > 0)
}
