// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
// Fixed synthetic inputs for notes/use-cases.md; no real user or market data.
fn require(condition : Bool, message : String) -> Unit {
  if !condition {
    abort(message)
  }
}

///|
fn main {
  println("设计场景 / 待验证：固定输入计算演示")
  println("【1 金额解析、权重分摊与对账】")
  let amount = match @money.Money::parse("100.00", "CNY") {
    Some(value) => value
    None => abort("fixed amount must parse")
  }
  let shares = match amount.allocate_by_weights([1, 2, 3]) {
    Some(value) => value
    None => abort("fixed weights must allocate")
  }
  for share in shares {
    println("  份额 CNY = " + share.to_decimal_string())
  }
  let total = match @money.Money::sum(shares, "CNY") {
    Some(value) => value
    None => abort("same-currency shares must sum")
  }
  if total != amount {
    abort("allocation must conserve amount")
  }
  println("  合计 CNY = " + total.to_decimal_string())
  let rejects_precision = @money.Money::parse("100.001", "CNY") == None
  require(rejects_precision, "excess precision must be rejected")
  println("  超精度解析被拒绝 = " + rejects_precision.to_string())
  let rejects_weights = amount.allocate_by_weights([0, 0, 0]) == None
  require(rejects_weights, "zero weights must be rejected")
  println("  全零权重被拒绝 = " + rejects_weights.to_string())

  println("【2 等间隔现金流审阅】")
  let cashflows = [-1000.0, 300.0, 400.0, 500.0]
  let breakdown = match
    @capital.discounted_cash_flow_schedule(0.10, cashflows) {
    Some(value) => value
    None => abort("fixed cashflows must discount")
  }
  for row in breakdown {
    println(
      "  t=" +
      row.period.to_string() +
      " 现金流=" +
      row.cashflow.to_string() +
      " 现值=" +
      row.present_value.to_string(),
    )
  }
  match @capital.net_present_value(0.10, cashflows) {
    Some(value) => {
      require((value - -21.0368145).abs() < 1.0e-6, "fixed NPV mismatch")
      println("  NPV = " + value.to_string())
    }
    None => abort("fixed cashflows must have NPV")
  }
  match @capital.internal_rate_of_return(cashflows) {
    Some(value) => println("  IRR = " + value.to_string())
    None => abort("fixed single-sign-change cashflows must have IRR")
  }
  match @capital.net_present_value(0.0, [1.0e16, 1.0, -1.0e16]) {
    Some(value) => {
      require(value == 1.0, "cancellation NPV must preserve the small term")
      println("  数值压力样例 NPV = " + value.to_string())
    }
    None => abort("fixed cancellation sample must have NPV")
  }
  let rejects_irr = @capital.internal_rate_of_return([-100.0, 230.0, -132.0]) ==
    None
  require(rejects_irr, "multiple-sign-change IRR must be rejected")
  println("  多次变号唯一 IRR 被拒绝 = " + rejects_irr.to_string())

  println("【3 按分还款计划与额外还本】")
  let principal = match @money.Money::parse("10000.00", "CNY") {
    Some(value) => value
    None => abort("fixed principal must parse")
  }
  let rows = match
    @amortize.equal_installment_money_schedule(
      principal,
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => abort("fixed loan must produce a plan")
  }
  for row in rows {
    println(
      "  期=" +
      row.period.to_string() +
      " 还款=" +
      row.payment.to_decimal_string() +
      " 本金=" +
      row.principal.to_decimal_string() +
      " 利息=" +
      row.interest.to_decimal_string() +
      " 余额=" +
      row.balance.to_decimal_string(),
    )
  }
  let baseline = match @amortize.summarize_money_schedule(rows) {
    Some(value) => value
    None => abort("baseline plan must reconcile")
  }
  require(baseline.principal == principal, "baseline principal mismatch")
  require(
    baseline.ending_balance == @money.Money::zero("CNY"),
    "baseline loan must settle",
  )
  println(
    "  基准汇总本金 CNY = " + baseline.principal.to_decimal_string(),
  )
  println("  基准总利息 CNY = " + baseline.interest.to_decimal_string())
  println(
    "  基准期末余额 CNY = " + baseline.ending_balance.to_decimal_string(),
  )
  let extra_rows = match
    @amortize.equal_installment_money_schedule_with_extra_principal(
      principal,
      0.01,
      12,
      [@money.Money::of(10000, "CNY")],
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => abort("fixed extra principal must produce a plan")
  }
  let extra = match @amortize.summarize_money_schedule(extra_rows) {
    Some(value) => value
    None => abort("extra-principal plan must reconcile")
  }
  require(extra.principal == principal, "extra-principal total mismatch")
  require(
    extra.ending_balance == @money.Money::zero("CNY"),
    "extra-principal loan must settle",
  )
  println(
    "  额外还本首期还款 CNY = " +
    extra_rows[0].payment.to_decimal_string(),
  )
  println(
    "  额外还本首期本金 CNY = " +
    extra_rows[0].principal.to_decimal_string(),
  )
  println(
    "  额外还本汇总本金 CNY = " + extra.principal.to_decimal_string(),
  )
  println("  额外还本总利息 CNY = " + extra.interest.to_decimal_string())
  println(
    "  额外还本期末余额 CNY = " +
    extra.ending_balance.to_decimal_string(),
  )
  let difference = match baseline.interest.try_sub(extra.interest) {
    Some(value) => value
    None => abort("fixed interest difference must fit Money")
  }
  require(difference.minor() == 1157, "fixed interest difference mismatch")
  println("  固定模型利息差 CNY = " + difference.to_decimal_string())
  let rejects_periods = @amortize.equal_installment_money_schedule(
      principal,
      0.01,
      0,
      @money.round_half_up(),
    ) ==
    None
  require(rejects_periods, "zero loan periods must be rejected")
  println("  零期数被拒绝 = " + rejects_periods.to_string())
}
