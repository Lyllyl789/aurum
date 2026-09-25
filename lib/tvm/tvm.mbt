// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 货币时间价值：现值、终值与年金的复利演算。
// 利率以小数表示（0.05 即年利率 5%），期数以整数计。
// 计算基于 IEEE-754 双精度浮点，适合教学与估算；
// 需要精确到分的场合，请结合 lib/money 的 round_div 原语。

///|
/// 单笔现金流的终值：FV = PV × (1 + r)^n。
pub fn future_value(pv : Double, rate : Double, periods : Int) -> Double {
  pv * @math.pow(1.0 + rate, periods.to_double())
}

///|
/// 单笔现金流的现值：PV = FV ÷ (1 + r)^n。
pub fn present_value(fv : Double, rate : Double, periods : Int) -> Double {
  fv * @math.pow(1.0 + rate, -periods.to_double())
}

///|
/// 普通年金终值（每期期末收付）：FV = PMT × [((1+r)^n − 1) / r]。
pub fn future_value_annuity(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double {
  if rate == 0.0 {
    payment * periods.to_double()
  } else {
    payment * (@math.pow(1.0 + rate, periods.to_double()) - 1.0) / rate
  }
}

///|
/// 普通年金现值（每期期末收付）：PV = PMT × [(1 − (1+r)^−n) / r]。
pub fn present_value_annuity(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double {
  if rate == 0.0 {
    payment * periods.to_double()
  } else {
    payment * (1.0 - @math.pow(1.0 + rate, -periods.to_double())) / rate
  }
}

///|
/// 期初年金终值：FV = 普通年金终值 × (1 + r)。
pub fn future_value_annuity_due(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double {
  future_value_annuity(payment, rate, periods) * (1.0 + rate)
}

///|
/// 期初年金现值：PV = 普通年金现值 × (1 + r)。
pub fn present_value_annuity_due(
  payment : Double,
  rate : Double,
  periods : Int,
) -> Double {
  present_value_annuity(payment, rate, periods) * (1.0 + rate)
}

///|
/// 永续年金现值：PV = PMT / r。
pub fn present_value_perpetuity(payment : Double, rate : Double) -> Double {
  if rate == 0.0 {
    abort("present_value_perpetuity: rate must be non-zero")
  }
  payment / rate
}

///|
/// 增长永续年金现值：PV = PMT / (r − g)，要求 r > g。
pub fn present_value_growing_perpetuity(
  payment : Double,
  rate : Double,
  growth : Double,
) -> Double {
  if rate <= growth {
    abort("present_value_growing_perpetuity: rate must exceed growth")
  }
  payment / (rate - growth)
}
