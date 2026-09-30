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
/// Minor-unit repayment row. Interest and principal are rounded each period;
/// the final payment is adjusted to clear the remaining balance exactly.
pub struct MoneyPayment {
  period : Int
  principal : @money.Money
  interest : @money.Money
  payment : @money.Money
  balance : @money.Money
} derive(Debug, Eq)

///|
/// Aggregate values from a minor-unit repayment schedule.
pub struct MoneyScheduleSummary {
  periods : Int
  principal : @money.Money
  interest : @money.Money
  payments : @money.Money
  ending_balance : @money.Money
} derive(Debug, Eq)

///|
fn round_nonnegative_to_int(value : Double, mode : @money.RoundMode) -> Int? {
  if !finite(value) || value < 0.0 || value > 2147483647.0 {
    return None
  }
  let truncated = value.to_int()
  let fraction = value - truncated.to_double()
  let increment = match mode {
    @money.Down => false
    @money.Up => fraction > 0.0
    @money.HalfUp => fraction >= 0.5
    @money.HalfEven => fraction > 0.5 || (fraction == 0.5 && truncated % 2 != 0)
  }
  if increment && truncated == 2147483647 {
    return None
  }
  Some(if increment { truncated + 1 } else { truncated })
}

///|
fn checked_minor_sum(a : Int, b : Int) -> Int? {
  let value = a.to_int64() + b.to_int64()
  if value < -2147483648L || value > 2147483647L {
    None
  } else {
    Some(value.to_int())
  }
}

///|
fn money_from_int64(value : Int64, currency : String) -> @money.Money? {
  if value < -2147483648L || value > 2147483647L {
    None
  } else {
    Some(@money.Money::of(value.to_int(), currency))
  }
}

///|
/// Validates and totals a complete schedule returned by one of the
/// minor-unit schedule functions. Rows must be numbered from one, reconcile
/// payment = principal + interest, and carry balances forward exactly.
pub fn summarize_money_schedule(
  rows : Array[MoneyPayment],
) -> MoneyScheduleSummary? {
  if rows.length() == 0 {
    return None
  }
  let currency = rows[0].payment.currency()
  let mut principal_total = 0L
  let mut interest_total = 0L
  let mut payment_total = 0L
  let mut previous_balance = 0
  let mut i = 0
  while i < rows.length() {
    let row = rows[i]
    if row.period != i + 1 ||
      row.principal.currency() != currency ||
      row.interest.currency() != currency ||
      row.payment.currency() != currency ||
      row.balance.currency() != currency ||
      row.principal.minor() < 0 ||
      row.interest.minor() < 0 ||
      row.balance.minor() < 0 {
      return None
    }
    let row_total = match
      checked_minor_sum(row.principal.minor(), row.interest.minor()) {
      Some(value) => value
      None => return None
    }
    if row.payment.minor() != row_total {
      return None
    }
    let row_opening = match
      checked_minor_sum(row.principal.minor(), row.balance.minor()) {
      Some(value) => value
      None => return None
    }
    if i > 0 && previous_balance != row_opening {
      return None
    }
    previous_balance = row.balance.minor()
    principal_total = principal_total + row.principal.minor().to_int64()
    interest_total = interest_total + row.interest.minor().to_int64()
    payment_total = payment_total + row.payment.minor().to_int64()
    i = i + 1
  }
  if previous_balance != 0 {
    return None
  }
  let principal = match money_from_int64(principal_total, currency) {
    Some(value) => value
    None => return None
  }
  let interest = match money_from_int64(interest_total, currency) {
    Some(value) => value
    None => return None
  }
  let payments = match money_from_int64(payment_total, currency) {
    Some(value) => value
    None => return None
  }
  Some({
    periods: rows.length(),
    principal,
    interest,
    payments,
    ending_balance: rows[rows.length() - 1].balance,
  })
}

///|
fn rounded_interest_minor(
  balance : Int,
  rate : Double,
  mode : @money.RoundMode,
) -> Int? {
  round_nonnegative_to_int(balance.to_double() * rate, mode)
}

///|
/// Builds an equal-installment loan plan in exact currency minor units.
/// Principal must be positive and the per-period rate nonnegative. Interest is
/// rounded from each opening balance; if rounding would pay off early, later
/// rows are zero. The final nonzero payment clears the balance exactly.
pub fn equal_installment_money_schedule(
  principal : @money.Money,
  rate : Double,
  periods : Int,
  mode : @money.RoundMode,
) -> Array[MoneyPayment]? {
  equal_installment_money_schedule_with_extra_principal(
    principal,
    rate,
    periods,
    [],
    mode,
  )
}

///|
/// Builds an equal-installment plan with optional extra principal payments.
/// `extra_principal[i]` is applied in period `i + 1`; omitted later periods are
/// treated as zero. Extras must be nonnegative and use the principal currency.
/// A payment above the remaining balance is capped, then later rows are zero.
pub fn equal_installment_money_schedule_with_extra_principal(
  principal : @money.Money,
  rate : Double,
  periods : Int,
  extra_principal : Array[@money.Money],
  mode : @money.RoundMode,
) -> Array[MoneyPayment]? {
  if principal.minor() <= 0 || !finite(rate) || rate < 0.0 || periods <= 0 {
    return None
  }
  if extra_principal.length() > periods {
    return None
  }
  let currency = principal.currency()
  for extra in extra_principal {
    if extra.currency() != currency || extra.minor() < 0 {
      return None
    }
  }
  let decimals = @money.currency_decimals(currency)
  let factor = @math.pow(10.0, decimals.to_double())
  let principal_major = principal.minor().to_double() / factor
  let regular_payment = match
    equal_installment_payment(principal_major, rate, periods) {
    Some(value) => value
    None => return None
  }
  let regular_minor = match
    round_nonnegative_to_int(regular_payment * factor, mode) {
    Some(value) => if value == 0 { 1 } else { value }
    None => return None
  }
  let zero = @money.Money::zero(currency)
  let placeholder = {
    period: 0,
    principal: zero,
    interest: zero,
    payment: zero,
    balance: zero,
  }
  let rows = Array::make(periods, placeholder)
  let mut balance = principal.minor()
  let mut i = 0
  while i < periods {
    if balance == 0 {
      rows[i] = {
        period: i + 1,
        principal: zero,
        interest: zero,
        payment: zero,
        balance: zero,
      }
    } else {
      let interest_minor = match rounded_interest_minor(balance, rate, mode) {
        Some(value) => value
        None => return None
      }
      let extra_minor = if i < extra_principal.length() {
        extra_principal[i].minor()
      } else {
        0
      }
      let scheduled_principal = match
        checked_minor_sum(regular_minor - interest_minor, extra_minor) {
        Some(value) => value
        None => return None
      }
      if scheduled_principal <= 0 && i + 1 < periods {
        return None
      }
      let principal_paid = if i + 1 == periods || scheduled_principal >= balance {
        balance
      } else {
        scheduled_principal
      }
      let payment_minor = match
        checked_minor_sum(principal_paid, interest_minor) {
        Some(value) => value
        None => return None
      }
      balance = balance - principal_paid
      rows[i] = {
        period: i + 1,
        principal: @money.Money::of(principal_paid, currency),
        interest: @money.Money::of(interest_minor, currency),
        payment: @money.Money::of(payment_minor, currency),
        balance: @money.Money::of(balance, currency),
      }
    }
    i = i + 1
  }
  Some(rows)
}

///|
/// Builds an equal-principal plan in minor units. Regular principal amounts
/// use integer division; any remainder is added to the final principal amount.
/// Interest is rounded each period and the final nonzero payment clears the
/// balance exactly.
pub fn equal_principal_money_schedule(
  principal : @money.Money,
  rate : Double,
  periods : Int,
  mode : @money.RoundMode,
) -> Array[MoneyPayment]? {
  if principal.minor() <= 0 || !finite(rate) || rate < 0.0 || periods <= 0 {
    return None
  }
  let currency = principal.currency()
  let regular_principal = principal.minor() / periods
  let final_principal = principal.minor() - regular_principal * (periods - 1)
  let zero = @money.Money::zero(currency)
  let placeholder = {
    period: 0,
    principal: zero,
    interest: zero,
    payment: zero,
    balance: zero,
  }
  let rows = Array::make(periods, placeholder)
  let mut balance = principal.minor()
  let mut i = 0
  while i < periods {
    if balance == 0 {
      rows[i] = {
        period: i + 1,
        principal: zero,
        interest: zero,
        payment: zero,
        balance: zero,
      }
    } else {
      let interest_minor = match rounded_interest_minor(balance, rate, mode) {
        Some(value) => value
        None => return None
      }
      let requested_principal = if i + 1 == periods {
        final_principal
      } else {
        regular_principal
      }
      let principal_paid = if i + 1 == periods || requested_principal >= balance {
        balance
      } else {
        requested_principal
      }
      let payment_minor = match
        checked_minor_sum(principal_paid, interest_minor) {
        Some(value) => value
        None => return None
      }
      balance = balance - principal_paid
      rows[i] = {
        period: i + 1,
        principal: @money.Money::of(principal_paid, currency),
        interest: @money.Money::of(interest_minor, currency),
        payment: @money.Money::of(payment_minor, currency),
        balance: @money.Money::of(balance, currency),
      }
    }
    i = i + 1
  }
  Some(rows)
}

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
    let exponent = -periods.to_double() * @math.ln_1p(rate)
    let denominator = -@math.expm1(exponent)
    let value = principal * rate / denominator
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
  let default = { period: 0, principal: 0.0, interest: 0.0, balance: 0.0, }
  let result = Array::make(periods, default)
  let mut balance = principal
  let mut i = 0
  while i < periods {
    let interest = balance * rate
    let principal_part = payment - interest
    balance = balance - principal_part
    if !finite(interest) || !finite(principal_part) || !finite(balance) {
      return None
    }
    result[i] = { period: i + 1, principal: principal_part, interest, balance, }
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
  if !finite(principal_part) {
    return None
  }
  let default = { period: 0, principal: 0.0, interest: 0.0, balance: 0.0, }
  let result = Array::make(periods, default)
  let mut balance = principal
  let mut i = 0
  while i < periods {
    let interest = balance * rate
    balance = balance - principal_part
    if !finite(interest) || !finite(balance) {
      return None
    }
    result[i] = { period: i + 1, principal: principal_part, interest, balance, }
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
  let value = principal * rate * (periods.to_double() + 1.0) / 2.0
  if finite(value) {
    Some(value)
  } else {
    None
  }
}
