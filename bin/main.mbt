// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// Aurum 命令行演示：货币时间价值与资本预算。
fn main {
  println("Aurum 财务计算演示")
  println("====================")

  // 货币时间价值
  let pv = 10000.0
  let rate = 0.05
  let years = 10
  println(
    "单笔终值：本金 " +
    pv.to_string() +
    " 元，年利率 5%，" +
    years.to_string() +
    " 年",
  )
  println("  FV = " + @tvm.future_value(pv, rate, years).to_string())

  let annuity_pmt = 1000.0
  let annuity_n = 20
  println(
    "普通年金现值：每期 " +
    annuity_pmt.to_string() +
    " 元，年利率 5%，" +
    annuity_n.to_string() +
    " 期",
  )
  println(
    "  PV = " +
    @tvm.present_value_annuity(annuity_pmt, rate, annuity_n).to_string(),
  )

  // 资本预算
  let cashflows = [-1000.0, 300.0, 400.0, 500.0]
  let discount = 0.10
  println("资本预算：现金流 [-1000, 300, 400, 500]，折现率 10%")
  println("  NPV = " + @capital.net_present_value(discount, cashflows).to_string())
  println("  IRR = " + @capital.internal_rate_of_return(cashflows).to_string())
  println(
    "  静态回收期 = " +
    @capital.payback_period(cashflows).to_string() +
    " 年",
  )
  println(
    "  盈利指数 = " +
    @capital.profitability_index(discount, cashflows).to_string(),
  )
}
