// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 固定资产折旧：直线法、双倍余额递减法、年数总和法与工作量法。
// 折旧额基于双精度浮点，适合教学与估算；精确到分的场合请结合 lib/money。
// 返回 Double?：None 表示非法输入或非有限结果。

///|
/// 有限性检查。
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
/// 直线法年折旧额：(成本 − 残值) / 使用年限。
pub fn straight_line_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
) -> Double? {
  if !finite(cost) || !finite(salvage) || life <= 0 {
    return None
  }
  let value = (cost - salvage) / life.to_double()
  if finite(value) {
    Some(value)
  } else {
    None
  }
}

///|
/// 双倍余额递减法第 year 年折旧额（year 从 1 起）。
/// 前 life − 2 年按账面净值 × (2 / life) 计提，最后两年转直线法摊到残值。
pub fn double_declining_balance_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
  year : Int,
) -> Double? {
  if !finite(cost) || !finite(salvage) || life <= 0 || year < 1 || year > life {
    return None
  }
  if life == 1 {
    let value = cost - salvage
    return if finite(value) { Some(value) } else { None }
  }
  let rate = 2.0 / life.to_double()
  let mut book = cost
  let mut i = 1
  while i <= life {
    let dep = if i >= life - 1 {
      (book - salvage) / (life - i + 1).to_double()
    } else {
      book * rate
    }
    if i == year {
      return if finite(dep) { Some(dep) } else { None }
    }
    book = book - dep
    if !finite(book) {
      return None
    }
    i = i + 1
  }
  let value = cost - salvage
  if finite(value) { Some(value) } else { None }
}

///|
/// 年数总和法第 year 年折旧额：按剩余使用年限占年数总和的比例计提。
pub fn sum_of_years_digits_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
  year : Int,
) -> Double? {
  if !finite(cost) || !finite(salvage) || life <= 0 || year < 1 || year > life {
    return None
  }
  let denominator = life * (life + 1) / 2
  let remaining = life - year + 1
  let value = (cost - salvage) * remaining.to_double() / denominator.to_double()
  if finite(value) {
    Some(value)
  } else {
    None
  }
}

///|
/// 工作量法折旧：按本期实际工作量占预计总工作量的比例分摊。
pub fn units_of_production_depreciation(
  cost : Double,
  salvage : Double,
  total_units : Double,
  units : Double,
) -> Double? {
  if !finite(cost) ||
    !finite(salvage) ||
    !finite(total_units) ||
    !finite(units) ||
    total_units <= 0.0 {
    return None
  }
  let value = (cost - salvage) * units / total_units
  if finite(value) {
    Some(value)
  } else {
    None
  }
}
