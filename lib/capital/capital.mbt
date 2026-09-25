// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 资本预算：净现值、内部收益率与回收期。
// 现金流以 Array[Double] 表示，下标 0 为第 0 期（通常为初始投入，负值），
// 后续各期为未来现金净流量；利率以小数表示。
// 折现复用了 lib/tvm 的现值原语，保持单笔与序列口径一致。

///|
/// 净现值：NPV = Σ CF_t / (1 + r)^t。
pub fn net_present_value(rate : Double, cashflows : Array[Double]) -> Double {
  let mut total = 0.0
  let mut t = 0
  while t < cashflows.length() {
    total = total + @tvm.present_value(cashflows[t], rate, t)
    t = t + 1
  }
  total
}

///|
/// 内部收益率：使净现值为零的折现率，采用二分法求解。
/// 要求现金流符号先负后正（标准投资），否则可能无解或多解。
pub fn internal_rate_of_return(cashflows : Array[Double]) -> Double {
  if cashflows.length() < 2 {
    abort("internal_rate_of_return: need at least two cash flows")
  }
  let mut lo = -0.99
  let mut hi = 10.0
  let mut f_lo = net_present_value(lo, cashflows)
  let mut f_hi = net_present_value(hi, cashflows)
  // 若两端符号相同，向上扩大上界寻找变号区间
  let mut steps = 0
  while f_lo * f_hi > 0.0 && steps < 60 {
    hi = hi * 2.0
    f_hi = net_present_value(hi, cashflows)
    steps = steps + 1
  }
  if f_lo * f_hi > 0.0 {
    abort("internal_rate_of_return: no sign change found")
  }
  // 二分迭代逼近根
  let mut iter = 0
  while iter < 200 {
    let mid = (lo + hi) / 2.0
    let f_mid = net_present_value(mid, cashflows)
    if f_lo * f_mid <= 0.0 {
      hi = mid
      f_hi = f_mid
    } else {
      lo = mid
      f_lo = f_mid
    }
    iter = iter + 1
  }
  (lo + hi) / 2.0
}

///|
/// 静态回收期：累计现金流首次转正所需年数（期内线性插值）。
pub fn payback_period(cashflows : Array[Double]) -> Double {
  if cashflows.length() == 0 {
    return 0.0
  }
  let mut cumulative = cashflows[0]
  if cumulative >= 0.0 {
    return 0.0
  }
  let mut prev = cumulative
  let mut t = 1
  while t < cashflows.length() {
    let cf = cashflows[t]
    cumulative = cumulative + cf
    if cumulative >= 0.0 {
      return (t - 1).to_double() + (-prev) / cf
    }
    prev = cumulative
    t = t + 1
  }
  cashflows.length().to_double()
}

///|
/// 折现回收期：以折现现金流计算的回收期。
pub fn discounted_payback_period(
  rate : Double,
  cashflows : Array[Double],
) -> Double {
  if cashflows.length() == 0 {
    return 0.0
  }
  let mut cumulative = cashflows[0]
  if cumulative >= 0.0 {
    return 0.0
  }
  let mut prev = cumulative
  let mut t = 1
  while t < cashflows.length() {
    let dcf = @tvm.present_value(cashflows[t], rate, t)
    cumulative = cumulative + dcf
    if cumulative >= 0.0 {
      return (t - 1).to_double() + (-prev) / dcf
    }
    prev = cumulative
    t = t + 1
  }
  cashflows.length().to_double()
}

///|
/// 盈利指数：PI = 未来现金流现值 / 初始投入。
pub fn profitability_index(rate : Double, cashflows : Array[Double]) -> Double {
  if cashflows.length() == 0 {
    abort("profitability_index: empty cash flows")
  }
  let initial = cashflows[0]
  if initial >= 0.0 {
    abort("profitability_index: initial cash flow must be negative")
  }
  let mut pv_future = 0.0
  let mut t = 1
  while t < cashflows.length() {
    pv_future = pv_future + @tvm.present_value(cashflows[t], rate, t)
    t = t + 1
  }
  pv_future / (-initial)
}
