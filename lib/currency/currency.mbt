// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 多币种：ISO 4217 货币元数据与汇率换算。
// 汇率以 Double 表示（1 单位源币种 = rate 单位目标币种），
// 换算结果四舍五入到目标币种的最小货币单位，返回精确金额。

///|
/// 有限性检查。
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
/// 货币元数据：ISO 4217 代码、符号与小数位数。
pub struct Currency {
  code : String
  symbol : String
  decimals : Int
} derive(Debug, Eq)

///|
/// 按 ISO 4217 代码查询货币元数据；未知代码返回 None。
pub fn lookup(code : String) -> Currency? {
  match code {
    "CNY" => Some({ code: "CNY", symbol: "¥", decimals: 2 })
    "USD" => Some({ code: "USD", symbol: "$", decimals: 2 })
    "EUR" => Some({ code: "EUR", symbol: "€", decimals: 2 })
    "GBP" => Some({ code: "GBP", symbol: "£", decimals: 2 })
    "JPY" => Some({ code: "JPY", symbol: "¥", decimals: 0 })
    "KRW" => Some({ code: "KRW", symbol: "₩", decimals: 0 })
    "VND" => Some({ code: "VND", symbol: "₫", decimals: 0 })
    "KWD" => Some({ code: "KWD", symbol: "KD", decimals: 3 })
    "BHD" => Some({ code: "BHD", symbol: "BD", decimals: 3 })
    "OMR" => Some({ code: "OMR", symbol: "RO", decimals: 3 })
    "JOD" => Some({ code: "JOD", symbol: "JD", decimals: 3 })
    "TND" => Some({ code: "TND", symbol: "DT", decimals: 3 })
    _ => None
  }
}

///|
/// 半向上取整到整数（远离零）。
fn round_half_up(x : Double) -> Int {
  if x >= 0.0 {
    (x + 0.5).to_int()
  } else {
    -((-x + 0.5).to_int())
  }
}

///|
/// 汇率换算：将金额按汇率换算为目标币种，结果四舍五入到目标币种最小单位。
/// rate 表示 1 单位源币种可兑换的目标币种数量；非法输入或未知币种返回 None。
pub fn convert(amount : @money.Money, target : String, rate : Double) -> @money.Money? {
  if !finite(rate) || rate <= 0.0 {
    return None
  }
  match lookup(amount.currency()) {
    None => None
    Some(src) =>
      match lookup(target) {
        None => None
        Some(dst) => {
          let scale = dst.decimals - src.decimals
          let scaled = amount.minor().to_double() * rate * @math.pow(10.0, scale.to_double())
          if !finite(scaled) {
            return None
          }
          Some(@money.Money::of(round_half_up(scaled), target))
        }
      }
  }
}

///|
/// 交叉汇率：1 单位 A = a_to_b 单位 B，1 单位 B = b_to_c 单位 C，
/// 则 1 单位 A = a_to_b × b_to_c 单位 C。
pub fn cross_rate(a_to_b : Double, b_to_c : Double) -> Double? {
  if !finite(a_to_b) || !finite(b_to_c) || a_to_b <= 0.0 || b_to_c <= 0.0 {
    return None
  }
  let result = a_to_b * b_to_c
  if finite(result) {
    Some(result)
  } else {
    None
  }
}
