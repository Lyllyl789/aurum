// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0

///|
/// Aurum 命令行演示：货币时间价值、资本预算、贷款摊销、固定资产折旧、
/// 债券定价、财务比率与多币种换算。
fn main {
  println("Aurum 财务计算演示")
  println("====================")

  // 货币时间价值
  println("【货币时间价值】")
  let rate = 0.05
  match @tvm.future_value(10000.0, rate, 10) {
    Some(value) => println("  本金 10000 元、年利率 5%、10 年的终值 = " + value.to_string())
    None => println("  终值无法计算")
  }
  match @tvm.present_value_annuity(1000.0, 0.05, 20) {
    Some(value) => println("  每期 1000 元、20 期普通年金的现值 = " + value.to_string())
    None => println("  年金现值无法计算")
  }

  // 资本预算
  println("【资本预算】")
  let cashflows = [-1000.0, 300.0, 400.0, 500.0]
  let discount = 0.10
  match @capital.net_present_value(discount, cashflows) {
    Some(value) => println("  现金流 [-1000, 300, 400, 500] 折现率 10% 的 NPV = " + value.to_string())
    None => println("  NPV 无法计算")
  }
  match @capital.internal_rate_of_return(cashflows) {
    Some(value) => println("  唯一 IRR = " + value.to_string())
    None => println("  唯一 IRR 无法确定")
  }

  // 贷款摊销
  println("【贷款摊销】")
  match @amortize.equal_installment_payment(10000.0, 0.01, 12) {
    Some(value) => println("  本金 10000 元、月利率 1%、12 期等额本息月供 = " + value.to_string())
    None => println("  月供无法计算")
  }
  match @amortize.total_interest_equal_installment(10000.0, 0.01, 12) {
    Some(value) => println("  等额本息总利息 = " + value.to_string())
    None => println("  总利息无法计算")
  }

  // 固定资产折旧
  println("【固定资产折旧】")
  match @wear.straight_line_depreciation(10000.0, 1000.0, 5) {
    Some(value) => println("  成本 10000、残值 1000、5 年直线法年折旧 = " + value.to_string())
    None => println("  折旧无法计算")
  }
  match @wear.sum_of_years_digits_depreciation(10000.0, 1000.0, 5, 1) {
    Some(value) => println("  年数总和法第 1 年折旧 = " + value.to_string())
    None => println("  折旧无法计算")
  }

  // 债券定价
  println("【债券定价】")
  match @bond.price(50.0, 1000.0, 0.05, 10) {
    Some(value) => println("  票息 50、面值 1000、收益率 5%、10 期债券价格 = " + value.to_string())
    None => println("  价格无法计算")
  }
  match @bond.yield_to_maturity(1000.0, 50.0, 1000.0, 10) {
    Some(value) => println("  平价债券到期收益率 = " + value.to_string())
    None => println("  到期收益率无法确定")
  }

  // 财务比率
  println("【财务比率】")
  match @ratio.current_ratio(1000.0, 500.0) {
    Some(value) => println("  流动比率 = " + value.to_string())
    None => println("  流动比率无法计算")
  }
  match @ratio.return_on_equity(100.0, 500.0) {
    Some(value) => println("  净资产收益率 ROE = " + value.to_string())
    None => println("  ROE 无法计算")
  }

  // 多币种换算
  println("【多币种换算】")
  let cny = @money.Money::of(10000, "CNY")
  match @currency.convert(cny, "USD", 0.14) {
    Some(usd) => println("  100.00 元按 0.14 汇率换算 = " + usd.format())
    None => println("  换算失败")
  }
}

