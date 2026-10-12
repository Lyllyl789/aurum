// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
fn main {
  let a = @money.Money::of(12345, "CNY")
  let b = @money.Money::of(100, "CNY")
  println("金额合计 CNY = " + a.add(b).to_decimal_string())
  let invoice = match @money.Money::parse("100.00", "CNY") {
    Some(value) => value
    None => abort("invalid invoice")
  }
  let shares = match invoice.allocate_by_weights([1, 2, 3]) {
    Some(value) => value
    None => abort("invalid weights")
  }
  for share in shares {
    println("份额 CNY = " + share.to_decimal_string())
  }
  match @tvm.future_value(10000.0, 0.05, 10) {
    Some(value) => println("终值估算 = " + value.to_string())
    None => abort("invalid TVM input or non-finite result")
  }
  match @capital.net_present_value(0.10, [-1000.0, 300.0, 400.0, 500.0]) {
    Some(value) => println("NPV 估算 = " + value.to_string())
    None => abort("invalid cashflows or non-finite result")
  }
  let rows = match
    @amortize.equal_installment_money_schedule(
      @money.Money::of(1000000, "CNY"),
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => abort("invalid loan input or overflow")
  }
  let summary = match @amortize.summarize_money_schedule(rows) {
    Some(value) => value
    None => abort("loan reconciliation failed or overflow")
  }
  println("贷款总利息 CNY = " + summary.interest.to_decimal_string())
  println(
    "贷款期末余额 CNY = " + summary.ending_balance.to_decimal_string(),
  )
}
