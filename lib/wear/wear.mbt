// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 固定资产折旧：直线法、双倍余额递减法、年数总和法与工作量法。
// 折旧额基于双精度浮点，适合教学与估算；精确到分的场合请结合 lib/money。

///|
/// 直线法年折旧额：(成本 − 残值) / 使用年限。
pub fn straight_line_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
) -> Double {
  if life <= 0 {
    abort("straight_line_depreciation: life must be positive")
  }
  (cost - salvage) / life.to_double()
}

///|
/// 双倍余额递减法第 year 年折旧额（year 从 1 起）。
/// 前 life − 2 年按账面净值 × (2 / life) 计提，最后两年转直线法摊到残值。
pub fn double_declining_balance_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
  year : Int,
) -> Double {
  if life <= 0 {
    abort("double_declining_balance_depreciation: life must be positive")
  }
  if year < 1 || year > life {
    abort("double_declining_balance_depreciation: year out of range")
  }
  if life == 1 {
    return cost - salvage
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
      return dep
    }
    book = book - dep
    i = i + 1
  }
  cost - salvage
}

///|
/// 年数总和法第 year 年折旧额：按剩余使用年限占年数总和的比例计提。
pub fn sum_of_years_digits_depreciation(
  cost : Double,
  salvage : Double,
  life : Int,
  year : Int,
) -> Double {
  if life <= 0 {
    abort("sum_of_years_digits_depreciation: life must be positive")
  }
  if year < 1 || year > life {
    abort("sum_of_years_digits_depreciation: year out of range")
  }
  let denominator = life * (life + 1) / 2
  let remaining = life - year + 1
  (cost - salvage) * remaining.to_double() / denominator.to_double()
}

///|
/// 工作量法折旧：按本期实际工作量占预计总工作量的比例分摊。
pub fn units_of_production_depreciation(
  cost : Double,
  salvage : Double,
  total_units : Double,
  units : Double,
) -> Double {
  if total_units <= 0.0 {
    abort("units_of_production_depreciation: total_units must be positive")
  }
  (cost - salvage) * units / total_units
}
