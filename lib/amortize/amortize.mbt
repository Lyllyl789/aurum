// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 贷款摊销：等额本息与等额本金的还款计划演算。
// 利率为“每期利率”（如月利率 = 年利率 / 12），期数以整数计。
// 计算基于双精度浮点，适合教学与估算；精确到分的场合请结合 lib/money。
// 返回 Double? / Array[Payment]?：None 表示非法输入或非有限结果。

///|
/// 有限性检查。
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
/// 每期还款明细：期号、本金、利息与期末剩余本金。
pub struct Payment {
  period : Int
  principal : Double
  interest : Double
  balance : Double
} derive(Debug, Eq)

///|
/// 等额本息每期还款额：PMT = P × r × (1+r)^n / ((1+r)^n − 1)。
pub fn equal_installment_payment(
  principal : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  if !finite(principal) || !finite(rate) || rate <= -1.0 || periods <= 0 {
    return None
  }
  if rate == 0.0 {
    let value = principal / periods.to_double()
    if finite(value) {
      Some(value)
    } else {
      None
    }
  } else {
    let factor = @math.pow(1.0 + rate, periods.to_double())
    let value = principal * rate * factor / (factor - 1.0)
    if finite(value) {
      Some(value)
    } else {
      None
    }
  }
}

///|
/// 等额本息还款计划：每期利息按剩余本金计息，本金为月供减利息。
pub fn equal_installment_schedule(
  principal : Double,
  rate : Double,
  periods : Int,
) -> Array[Payment]? {
  let payment = match equal_installment_payment(principal, rate, periods) {
    Some(value) => value
    None => return None
  }
  let default = { period: 0, principal: 0.0, interest: 0.0, balance: 0.0 }
  let result = Array::make(periods, default)
  let mut balance = principal
  let mut i = 0
  while i < periods {
    let interest = balance * rate
    let principal_part = payment - interest
    balance = balance - principal_part
    if !finite(balance) {
      return None
    }
    result[i] = { period: i + 1, principal: principal_part, interest: interest, balance: balance }
    i = i + 1
  }
  Some(result)
}

///|
/// 等额本金还款计划：每期本金固定为 P / n，利息随余额递减。
pub fn equal_principal_schedule(
  principal : Double,
  rate : Double,
  periods : Int,
) -> Array[Payment]? {
  if !finite(principal) || !finite(rate) || rate <= -1.0 || periods <= 0 {
    return None
  }
  let principal_part = principal / periods.to_double()
  let default = { period: 0, principal: 0.0, interest: 0.0, balance: 0.0 }
  let result = Array::make(periods, default)
  let mut balance = principal
  let mut i = 0
  while i < periods {
    let interest = balance * rate
    balance = balance - principal_part
    if !finite(balance) {
      return None
    }
    result[i] = { period: i + 1, principal: principal_part, interest: interest, balance: balance }
    i = i + 1
  }
  Some(result)
}

///|
/// 等额本息总利息 = 每期还款额 × 期数 − 本金。
pub fn total_interest_equal_installment(
  principal : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  match equal_installment_payment(principal, rate, periods) {
    Some(payment) => {
      let value = payment * periods.to_double() - principal
      if finite(value) {
        Some(value)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// 等额本金总利息 = P × r × (n + 1) / 2。
pub fn total_interest_equal_principal(
  principal : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  if !finite(principal) || !finite(rate) || rate <= -1.0 || periods <= 0 {
    return None
  }
  let value = principal * rate * (periods + 1).to_double() / 2.0
  if finite(value) {
    Some(value)
  } else {
    None
  }
}
