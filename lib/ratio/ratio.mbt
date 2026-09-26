// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 财务比率：流动性、偿债能力、盈利能力、营运能力与估值指标。
// 所有指标以 Double 计算，分母为零或结果非有限时返回 None。

///|
/// 有限性检查。
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
/// 计算比值，分母为零或结果非有限时返回 None。
fn ratio(numerator : Double, denominator : Double) -> Double? {
  if denominator == 0.0 {
    return None
  }
  let value = numerator / denominator
  if finite(value) {
    Some(value)
  } else {
    None
  }
}

///|
/// 流动比率 = 流动资产 / 流动负债。
pub fn current_ratio(current_assets : Double, current_liabilities : Double) -> Double? {
  ratio(current_assets, current_liabilities)
}

///|
/// 速动比率 = (流动资产 − 存货) / 流动负债。
pub fn quick_ratio(
  current_assets : Double,
  inventory : Double,
  current_liabilities : Double,
) -> Double? {
  ratio(current_assets - inventory, current_liabilities)
}

///|
/// 资产负债率 = 总负债 / 总资产。
pub fn debt_to_assets(total_liabilities : Double, total_assets : Double) -> Double? {
  ratio(total_liabilities, total_assets)
}

///|
/// 利息保障倍数 = 息税前利润 / 利息费用。
pub fn interest_coverage(ebit : Double, interest_expense : Double) -> Double? {
  ratio(ebit, interest_expense)
}

///|
/// 毛利率 = 毛利 / 营业收入。
pub fn gross_margin(gross_profit : Double, revenue : Double) -> Double? {
  ratio(gross_profit, revenue)
}

///|
/// 净利率 = 净利润 / 营业收入。
pub fn net_margin(net_income : Double, revenue : Double) -> Double? {
  ratio(net_income, revenue)
}

///|
/// 净资产收益率 = 净利润 / 股东权益。
pub fn return_on_equity(net_income : Double, equity : Double) -> Double? {
  ratio(net_income, equity)
}

///|
/// 总资产收益率 = 净利润 / 总资产。
pub fn return_on_assets(net_income : Double, total_assets : Double) -> Double? {
  ratio(net_income, total_assets)
}

///|
/// 总资产周转率 = 营业收入 / 总资产。
pub fn asset_turnover(revenue : Double, total_assets : Double) -> Double? {
  ratio(revenue, total_assets)
}

///|
/// 存货周转率 = 营业成本 / 平均存货。
pub fn inventory_turnover(
  cost_of_goods_sold : Double,
  average_inventory : Double,
) -> Double? {
  ratio(cost_of_goods_sold, average_inventory)
}

///|
/// 市盈率 = 每股市价 / 每股收益。
pub fn price_earnings_ratio(
  price_per_share : Double,
  earnings_per_share : Double,
) -> Double? {
  ratio(price_per_share, earnings_per_share)
}

///|
/// 市净率 = 每股市价 / 每股净资产。
pub fn price_to_book(
  price_per_share : Double,
  book_value_per_share : Double,
) -> Double? {
  ratio(price_per_share, book_value_per_share)
}

///|
/// 每股收益 = 净利润 / 流通在外普通股股数。
pub fn earnings_per_share(net_income : Double, shares_outstanding : Double) -> Double? {
  ratio(net_income, shares_outstanding)
}
