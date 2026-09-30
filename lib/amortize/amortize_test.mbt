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
test "equal installment payment" {
  // 本金 10000，月利率 1%，12 期：月供约 888.49
  assert_true(
    approx(equal_installment_payment(10000.0, 0.01, 12), 888.4878869, 1.0e-6),
  )
  // 零利率时即为等额分摊
  assert_true(
    approx(equal_installment_payment(10000.0, 0.0, 12), 833.3333333, 1.0e-6),
  )
  assert_true(
    approx(equal_installment_payment(10000.0, 1.0e-12, 12), 833.3333333, 1.0e-6),
  )
}

///|
test "equal installment schedule" {
  match equal_installment_schedule(10000.0, 0.01, 12) {
    Some(s) => {
      assert_eq(s.length(), 12)
      assert_true((s[0].interest - 100.0).abs() < 1.0e-9)
      assert_true((s[11].balance - 0.0).abs() < 1.0e-6)
      let mut sum = 0.0
      let mut i = 0
      while i < s.length() {
        sum = sum + s[i].principal
        i = i + 1
      }
      assert_true((sum - 10000.0).abs() < 1.0e-6)
    }
    None => fail("expected a schedule")
  }
}

///|
test "equal principal schedule" {
  match equal_principal_schedule(10000.0, 0.01, 12) {
    Some(s) => {
      assert_eq(s.length(), 12)
      assert_true((s[0].principal - 833.3333333).abs() < 1.0e-6)
      assert_true((s[0].interest - 100.0).abs() < 1.0e-9)
      assert_true((s[11].balance - 0.0).abs() < 1.0e-6)
    }
    None => fail("expected a schedule")
  }
}

///|
test "total interest" {
  assert_true(
    approx(
      total_interest_equal_installment(10000.0, 0.01, 12),
      661.8546414,
      1.0e-6,
    ),
  )
  assert_true(
    approx(total_interest_equal_principal(10000.0, 0.01, 12), 650.0, 1.0e-9),
  )
}

///|
test "invalid inputs return None" {
  assert_true(equal_installment_payment(10000.0, 0.01, 0) == None)
  assert_true(equal_installment_payment(10000.0, 0.01, -1) == None)
  assert_true(equal_installment_schedule(10000.0, -1.0, 12) == None)
  assert_true(equal_principal_schedule(10000.0, 0.01, 0) == None)
  assert_true(total_interest_equal_installment(10000.0, 0.01, 0) == None)
  assert_true(total_interest_equal_principal(10000.0, 0.01, 0) == None)
}

///|
test "schedules reject non finite fields" {
  assert_true(equal_principal_schedule(1.0e308, 10.0, 2) == None)
}

///|
test "equal principal total interest handles large period count" {
  assert_true(
    approx(
      total_interest_equal_principal(1.0, 0.01, 2147483647),
      10737418.24,
      1.0e-6,
    ),
  )
}

///|
test "minor-unit equal-installment schedule reconciles every row" {
  let principal = @money.Money::of(1000000, "CNY")
  match
    equal_installment_money_schedule(
      principal,
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(rows) => {
      assert_eq(rows.length(), 12)
      assert_eq(rows[0].payment.minor(), 88849)
      assert_eq(rows[0].interest.minor(), 10000)
      assert_eq(rows[11].balance.minor(), 0)
      let mut principal_total = 0
      let mut payment_total = 0
      let mut i = 0
      while i < rows.length() {
        assert_eq(
          rows[i].payment.minor(),
          rows[i].principal.minor() + rows[i].interest.minor(),
        )
        if i > 0 {
          assert_eq(
            rows[i - 1].balance.minor() - rows[i].principal.minor(),
            rows[i].balance.minor(),
          )
        }
        principal_total = principal_total + rows[i].principal.minor()
        payment_total = payment_total + rows[i].payment.minor()
        i = i + 1
      }
      assert_eq(principal_total, principal.minor())
      assert_true(payment_total > principal_total)
      match summarize_money_schedule(rows) {
        Some(summary) => {
          assert_eq(summary.periods, 12)
          assert_eq(summary.principal.minor(), principal.minor())
          assert_eq(summary.payments.minor(), payment_total)
          assert_eq(summary.ending_balance.minor(), 0)
        }
        None => fail("expected schedule summary")
      }
    }
    None => fail("expected money schedule")
  }
}

///|
test "minor-unit equal-principal schedule places remainder in final period" {
  let principal = @money.Money::of(1000, "CNY")
  match
    equal_principal_money_schedule(principal, 0.0, 3, @money.round_half_up()) {
    Some(rows) => {
      assert_eq(rows[0].principal.minor(), 333)
      assert_eq(rows[1].principal.minor(), 333)
      assert_eq(rows[2].principal.minor(), 334)
      assert_eq(rows[2].balance.minor(), 0)
      assert_eq(
        rows[0].payment.minor() +
        rows[1].payment.minor() +
        rows[2].payment.minor(),
        principal.minor(),
      )
    }
    None => fail("expected equal-principal money schedule")
  }
}

///|
test "minor-unit loan schedules handle early payoff and currency scale" {
  match
    equal_installment_money_schedule(
      @money.Money::of(2, "CNY"),
      0.0,
      4,
      @money.round_half_up(),
    ) {
    Some(rows) => {
      assert_eq(rows[0].principal.minor(), 1)
      assert_eq(rows[1].principal.minor(), 1)
      assert_eq(rows[1].balance.minor(), 0)
      assert_eq(rows[2].payment.minor(), 0)
      assert_eq(rows[3].payment.minor(), 0)
    }
    None => fail("expected early payoff schedule")
  }
  match
    equal_principal_money_schedule(
      @money.Money::of(1234, "JPY"),
      0.0,
      2,
      @money.round_half_up(),
    ) {
    Some(rows) => {
      assert_eq(rows[0].principal.minor(), 617)
      assert_eq(rows[1].principal.minor(), 617)
      assert_eq(rows[1].balance.minor(), 0)
    }
    None => fail("expected JPY schedule")
  }
}

///|
test "minor-unit schedules reject invalid or unrepresentable inputs" {
  let principal = @money.Money::of(10000, "USD")
  assert_true(
    equal_installment_money_schedule(
      principal,
      -0.01,
      12,
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule(
      principal,
      @double.infinity,
      12,
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule(principal, 0.01, 0, @money.round_half_up()) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule(
      @money.Money::zero("USD"),
      0.01,
      12,
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule(
      @money.Money::of(2147483647, "JPY"),
      1.0,
      1,
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_principal_money_schedule(principal, -0.01, 12, @money.round_half_up()) ==
    None,
  )
  assert_true(
    equal_principal_money_schedule(principal, 0.01, -1, @money.round_half_up()) ==
    None,
  )
}

///|
test "money schedule summary rejects empty schedule" {
  assert_true(summarize_money_schedule([]) == None)
}

///|
test "minor-unit schedules reconcile a grid of small principal and terms" {
  let mut minor = 1
  while minor <= 80 {
    let mut periods = 1
    while periods <= 12 {
      let principal = @money.Money::of(minor, "CNY")
      let rows = match
        equal_installment_money_schedule(
          principal,
          0.01,
          periods,
          @money.round_half_up(),
        ) {
        Some(value) => value
        None => fail("small valid loan must produce a schedule")
      }
      let summary = match summarize_money_schedule(rows) {
        Some(value) => value
        None => fail("small loan schedule must reconcile")
      }
      assert_eq(summary.principal, principal)
      assert_eq(summary.ending_balance.minor(), 0)
      periods = periods + 1
    }
    minor = minor + 1
  }
}

///|
test "extra principal shortens repayment while preserving exact reconciliation" {
  let principal = @money.Money::of(1000000, "CNY")
  let extra = [@money.Money::of(10000, "CNY")]
  let rows = match
    equal_installment_money_schedule_with_extra_principal(
      principal,
      0.01,
      12,
      extra,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => fail("expected extra-payment plan")
  }
  let summary = match summarize_money_schedule(rows) {
    Some(value) => value
    None => fail("extra-payment plan must reconcile")
  }
  let baseline = match
    equal_installment_money_schedule(
      principal,
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => fail("expected baseline plan")
  }
  let baseline_summary = match summarize_money_schedule(baseline) {
    Some(value) => value
    None => fail("baseline plan must reconcile")
  }
  assert_eq(rows[0].principal.minor(), 88849)
  assert_eq(rows[0].payment.minor(), 98849)
  assert_true(summary.interest.minor() < baseline_summary.interest.minor())
  assert_eq(summary.ending_balance.minor(), 0)
}

///|
test "extra principal inputs must be valid for the loan" {
  let principal = @money.Money::of(10000, "USD")
  assert_true(
    equal_installment_money_schedule_with_extra_principal(
      principal,
      0.01,
      2,
      [@money.Money::of(1, "EUR")],
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule_with_extra_principal(
      principal,
      0.01,
      2,
      [@money.Money::of(-1, "USD")],
      @money.round_half_up(),
    ) ==
    None,
  )
  assert_true(
    equal_installment_money_schedule_with_extra_principal(
      principal,
      0.01,
      1,
      [@money.Money::zero("USD"), @money.Money::zero("USD")],
      @money.round_half_up(),
    ) ==
    None,
  )
}
