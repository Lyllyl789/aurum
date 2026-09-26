// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// TVM uses IEEE-754 Double for estimates, not exact monetary amounts.
// None means invalid input or a non-finite computed result.

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
fn valid_term(amount : Double, rate : Double, periods : Int) -> Bool {
  finite(amount) && finite(rate) && rate > -1.0 && periods >= 0
}

///|
fn checked(value : Double) -> Double? {
  if finite(value) {
    Some(value)
  } else {
    None
  }
}

///|
/// FV = PV × (1+r)^n. None for non-finite values, r <= -1, or n < 0.
pub fn future_value(pv : Double, rate : Double, periods : Int) -> Double? {
  if !valid_term(pv, rate, periods) {
    return None
  }
  checked(pv * @math.pow(1.0 + rate, periods.to_double()))
}

///|
/// PV = FV / (1+r)^n. Uses a negative exponent to avoid overflow in the divisor.
pub fn present_value(fv : Double, rate : Double, periods : Int) -> Double? {
  if !valid_term(fv, rate, periods) {
    return None
  }
  checked(fv * @math.pow(1.0 + rate, -periods.to_double()))
}

///|
/// Ordinary annuity FV; zero periods yield zero. None on invalid or non-finite output.
pub fn future_value_annuity(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  if !valid_term(payment, rate, periods) {
    return None
  }
  if periods == 0 {
    return Some(0.0)
  }
  if rate == 0.0 {
    return checked(payment * periods.to_double())
  }
  checked(
    payment * (@math.expm1(periods.to_double() * @math.ln_1p(rate)) / rate),
  )
}

///|
/// Ordinary annuity PV; zero periods yield zero. None on invalid or non-finite output.
pub fn present_value_annuity(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  if !valid_term(payment, rate, periods) {
    return None
  }
  if periods == 0 {
    return Some(0.0)
  }
  if rate == 0.0 {
    return checked(payment * periods.to_double())
  }
  checked(
    payment * (-@math.expm1(-periods.to_double() * @math.ln_1p(rate)) / rate),
  )
}

///|
/// Annuity due FV = ordinary annuity FV × (1+r).
pub fn future_value_annuity_due(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  match future_value_annuity(payment, rate, periods) {
    Some(value) => checked(value * (1.0 + rate))
    None => None
  }
}

///|
/// Annuity due PV = ordinary annuity PV × (1+r).
pub fn present_value_annuity_due(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double? {
  match present_value_annuity(payment, rate, periods) {
    Some(value) => checked(value * (1.0 + rate))
    None => None
  }
}

///|
/// Perpetuity PV = payment / rate; requires a strictly positive discount rate.
pub fn present_value_perpetuity(payment : Double, rate : Double) -> Double? {
  if !finite(payment) || !finite(rate) || rate <= 0.0 {
    return None
  }
  checked(payment / rate)
}

///|
/// Growing perpetuity PV = payment / (rate-growth); requires rate > growth > -1.
pub fn present_value_growing_perpetuity(
  payment : Double,
  rate : Double,
  growth : Double,
) -> Double? {
  if !finite(payment) ||
    !finite(rate) ||
    !finite(growth) ||
    growth <= -1.0 ||
    rate <= growth {
    return None
  }
  checked(payment / (rate - growth))
}
