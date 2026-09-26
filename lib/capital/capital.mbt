// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// Capital budgeting uses finite Double estimates. None denotes invalid input,
// a non-finite computation, or an unavailable estimate.

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
fn valid_cashflows(cashflows : Array[Double]) -> Bool {
  if cashflows.length() == 0 {
    return false
  }
  for cf in cashflows {
    if !finite(cf) {
      return false
    }
  }
  true
}

///|
fn valid_rate(rate : Double) -> Bool {
  finite(rate) && rate > -1.0
}

///|
/// NPV = Σ CF_t / (1+r)^t. None for empty/non-finite cash flows,
/// an invalid rate, or a non-finite intermediate sum.
pub fn net_present_value(rate : Double, cashflows : Array[Double]) -> Double? {
  if !valid_rate(rate) || !valid_cashflows(cashflows) {
    return None
  }
  let mut total = 0.0
  let mut t = 0
  while t < cashflows.length() {
    match @tvm.present_value(cashflows[t], rate, t) {
      Some(value) => {
        total = total + value
        if !finite(total) {
          return None
        }
      }
      None => return None
    }
    t = t + 1
  }
  Some(total)
}

///|
// One sign change in the cash-flow coefficients guarantees at most one
// positive root in x = 1/(1+r). Zero coefficients do not change the count.
fn one_sign_change(cashflows : Array[Double]) -> Bool {
  let mut previous = 0
  let mut changes = 0
  for cf in cashflows {
    let sign = if cf > 0.0 { 1 } else if cf < 0.0 { -1 } else { 0 }
    if sign != 0 {
      if previous != 0 && sign != previous {
        changes = changes + 1
      }
      previous = sign
    }
  }
  changes == 1
}

///|
/// Finds a unique IRR in the inclusive interval [lower, upper]. Returns None
/// for invalid input, zero or multiple cash-flow sign changes, no bracketed
/// root, non-finite NPV, or failure to reach a relative width of 1e-12 in
/// 256 bisections. The one-sign-change rule conservatively rejects ambiguous
/// patterns even when a particular pattern happens to have one real IRR.
pub fn internal_rate_of_return_in_range(
  cashflows : Array[Double],
  lower : Double,
  upper : Double,
) -> Double? {
  if cashflows.length() < 2 ||
    !valid_cashflows(cashflows) ||
    !one_sign_change(cashflows) ||
    !valid_rate(lower) ||
    !valid_rate(upper) ||
    lower >= upper {
    return None
  }
  let mut lo = lower
  let mut hi = upper
  let mut f_lo = match net_present_value(lo, cashflows) {
    Some(value) => value
    None => return None
  }
  let f_hi = match net_present_value(hi, cashflows) {
    Some(value) => value
    None => return None
  }
  if f_lo == 0.0 {
    return Some(lo)
  }
  if f_hi == 0.0 {
    return Some(hi)
  }
  if (f_lo > 0.0) == (f_hi > 0.0) {
    return None
  }
  let mut iter = 0
  while iter < 256 {
    let mid = lo + (hi - lo) / 2.0
    if mid == lo || mid == hi {
      return Some(mid)
    }
    let f_mid = match net_present_value(mid, cashflows) {
      Some(value) => value
      None => return None
    }
    if f_mid == 0.0 {
      return Some(mid)
    }
    if (f_lo > 0.0) == (f_mid > 0.0) {
      lo = mid
      f_lo = f_mid
    } else {
      hi = mid
    }
    if hi - lo <= 1.0e-12 * (1.0 + mid.abs()) {
      return Some(lo + (hi - lo) / 2.0)
    }
    iter = iter + 1
  }
  None
}

///|
/// Unique IRR searched in [-0.999999999999, 1e12].
/// Use internal_rate_of_return_in_range for other bounds.
pub fn internal_rate_of_return(cashflows : Array[Double]) -> Double? {
  internal_rate_of_return_in_range(cashflows, -0.999999999999, 1.0e12)
}

///|
/// First undiscounted recovery time with linear interpolation within a period.
/// None means invalid cash flows or no recovery during the supplied horizon.
pub fn payback_period(cashflows : Array[Double]) -> Double? {
  if !valid_cashflows(cashflows) {
    return None
  }
  let mut cumulative = cashflows[0]
  if cumulative >= 0.0 {
    return Some(0.0)
  }
  let mut t = 1
  while t < cashflows.length() {
    let previous = cumulative
    cumulative = cumulative + cashflows[t]
    if !finite(cumulative) {
      return None
    }
    if cumulative >= 0.0 {
      return Some((t - 1).to_double() + -previous / cashflows[t])
    }
    t = t + 1
  }
  None
}

///|
/// First discounted recovery time. None means invalid input, a non-finite
/// calculation, or no recovery during the supplied horizon.
pub fn discounted_payback_period(
  rate : Double,
  cashflows : Array[Double],
) -> Double? {
  if !valid_rate(rate) || !valid_cashflows(cashflows) {
    return None
  }
  let mut cumulative = cashflows[0]
  if cumulative >= 0.0 {
    return Some(0.0)
  }
  let mut t = 1
  while t < cashflows.length() {
    let previous = cumulative
    let dcf = match @tvm.present_value(cashflows[t], rate, t) {
      Some(value) => value
      None => return None
    }
    cumulative = cumulative + dcf
    if !finite(cumulative) {
      return None
    }
    if cumulative >= 0.0 {
      return Some((t - 1).to_double() + -previous / dcf)
    }
    t = t + 1
  }
  None
}

///|
/// PI = present value of future cash flows / initial investment.
/// Requires a strictly negative initial flow and finite result.
pub fn profitability_index(rate : Double, cashflows : Array[Double]) -> Double? {
  if !valid_rate(rate) || !valid_cashflows(cashflows) || cashflows[0] >= 0.0 {
    return None
  }
  let mut pv_future = 0.0
  let mut t = 1
  while t < cashflows.length() {
    match @tvm.present_value(cashflows[t], rate, t) {
      Some(value) => {
        pv_future = pv_future + value
        if !finite(pv_future) {
          return None
        }
      }
      None => return None
    }
    t = t + 1
  }
  let result = pv_future / -cashflows[0]
  if finite(result) {
    Some(result)
  } else {
    None
  }
}
