// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 债券定价：价格、到期收益率、久期与凸性。
// 票息与面值为每期现金流，yld 为每期折现率；依赖 lib/tvm 的现值原语。
// 返回 Double?：None 表示非法输入或非有限结果。

///|
/// 有限性检查。
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
/// 债券价格 = 票息年金现值 + 面值现值。
pub fn price(coupon : Double, face : Double, yld : Double, periods : Int) -> Double? {
  if !finite(coupon) || !finite(face) || !finite(yld) || periods <= 0 {
    return None
  }
  match @tvm.present_value_annuity(coupon, yld, periods) {
    Some(coupon_pv) =>
      match @tvm.present_value(face, yld, periods) {
        Some(face_pv) => {
          let total = coupon_pv + face_pv
          if finite(total) {
            Some(total)
          } else {
            None
          }
        }
        None => None
      }
    None => None
  }
}

///|
/// 债券价格与目标价之差（二分法求根用）。
fn price_difference(
  yld : Double,
  coupon : Double,
  face : Double,
  periods : Int,
  target : Double,
) -> Double? {
  match price(coupon, face, yld, periods) {
    Some(p) => {
      let d = p - target
      if finite(d) {
        Some(d)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// 到期收益率：使债券现金流现值等于市价的折现率，采用二分法。
pub fn yield_to_maturity(
  market_price : Double,
  coupon : Double,
  face : Double,
  periods : Int,
) -> Double? {
  if !finite(market_price) || !finite(coupon) || !finite(face) || periods <= 0 {
    return None
  }
  let mut lo = -0.999999999999
  let mut hi = 10.0
  let mut f_lo = match price_difference(lo, coupon, face, periods, market_price) {
    Some(value) => value
    None => return None
  }
  let mut f_hi = match price_difference(hi, coupon, face, periods, market_price) {
    Some(value) => value
    None => return None
  }
  let mut steps = 0
  while (f_lo > 0.0) == (f_hi > 0.0) && steps < 60 {
    hi = hi * 2.0
    match price_difference(hi, coupon, face, periods, market_price) {
      Some(value) => f_hi = value
      None => return None
    }
    steps = steps + 1
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
    let f_mid = match price_difference(mid, coupon, face, periods, market_price) {
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
/// 麦考利久期：D = Σ t·CF_t/(1+y)^t / P。
pub fn macaulay_duration(
  coupon : Double,
  face : Double,
  yld : Double,
  periods : Int,
) -> Double? {
  if !finite(coupon) || !finite(face) || !finite(yld) || periods <= 0 {
    return None
  }
  let bond_price = match price(coupon, face, yld, periods) {
    Some(p) => p
    None => return None
  }
  if bond_price == 0.0 {
    return None
  }
  let mut weighted = 0.0
  let mut t = 1
  while t <= periods {
    let cf = if t == periods { coupon + face } else { coupon }
    match @tvm.present_value(cf, yld, t) {
      Some(pv) => {
        weighted = weighted + t.to_double() * pv
        if !finite(weighted) {
          return None
        }
      }
      None => return None
    }
    t = t + 1
  }
  let result = weighted / bond_price
  if finite(result) {
    Some(result)
  } else {
    None
  }
}

///|
/// 修正久期 = 麦考利久期 / (1 + yld)。
pub fn modified_duration(
  coupon : Double,
  face : Double,
  yld : Double,
  periods : Int,
) -> Double? {
  match macaulay_duration(coupon, face, yld, periods) {
    Some(d) => {
      let result = d / (1.0 + yld)
      if finite(result) {
        Some(result)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// 凸性：Conv = Σ t(t+1)·CF_t/(1+y)^(t+2) / P。
pub fn convexity(
  coupon : Double,
  face : Double,
  yld : Double,
  periods : Int,
) -> Double? {
  if !finite(coupon) || !finite(face) || !finite(yld) || periods <= 0 {
    return None
  }
  let bond_price = match price(coupon, face, yld, periods) {
    Some(p) => p
    None => return None
  }
  if bond_price == 0.0 {
    return None
  }
  let mut weighted = 0.0
  let mut t = 1
  while t <= periods {
    let cf = if t == periods { coupon + face } else { coupon }
    let pv_factor = @math.pow(1.0 + yld, (t + 2).to_double())
    weighted = weighted + cf * t.to_double() * (t + 1).to_double() / pv_factor
    if !finite(weighted) {
      return None
    }
    t = t + 1
  }
  let result = weighted / bond_price
  if finite(result) {
    Some(result)
  } else {
    None
  }
}
