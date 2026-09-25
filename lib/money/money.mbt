// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 精确金额：以最小货币单位（分）为存储基础的整数运算。
// 金融计算中，二进制浮点会引入 0.1 + 0.2 != 0.3 一类的误差，
// 因此 Aurum 全程使用整数分，从根源上规避精度丢失。

///|
/// 舍入策略。
pub enum RoundMode {
  HalfUp
  HalfEven
  Down
  Up
} derive(Debug, Eq)

///|
/// 返回“四舍五入”舍入策略。
/// 无负载枚举在 blackbox 测试与外部调用中不可直接构造，故提供构造辅助函数。
pub fn round_half_up() -> RoundMode {
  HalfUp
}

///|
/// 返回“四舍六入五成双”舍入策略。
pub fn round_half_even() -> RoundMode {
  HalfEven
}

///|
/// 返回“向下取整”舍入策略。
pub fn round_down() -> RoundMode {
  Down
}

///|
/// 返回“向上取整”舍入策略。
pub fn round_up() -> RoundMode {
  Up
}

///|
/// 精确金额，以最小货币单位 `minor` 存储（如 CNY 的分、USD 的 cent）。
/// `currency` 为 ISO 4217 三位代码。
pub struct Money {
  minor : Int
  currency : String
} derive(Debug, Eq)

///|
/// 以最小货币单位构造金额。
pub fn Money::of(minor : Int, currency : String) -> Money {
  { minor, currency }
}

///|
/// 构造零金额。
pub fn Money::zero(currency : String) -> Money {
  { minor: 0, currency }
}

///|
/// 金额相加。约定双方货币一致，调用方负责校验。
pub fn Money::add(self : Money, other : Money) -> Money {
  { minor: self.minor + other.minor, currency: self.currency }
}

///|
/// 金额相减。
pub fn Money::sub(self : Money, other : Money) -> Money {
  { minor: self.minor - other.minor, currency: self.currency }
}

///|
/// 取相反数。
pub fn Money::neg(self : Money) -> Money {
  { minor: -self.minor, currency: self.currency }
}

///|
/// 按整数倍缩放金额（乘以标量）。
pub fn Money::scale(self : Money, factor : Int) -> Money {
  { minor: self.minor * factor, currency: self.currency }
}

///|
pub fn Money::is_zero(self : Money) -> Bool {
  self.minor == 0
}

///|
pub fn Money::is_positive(self : Money) -> Bool {
  self.minor > 0
}

///|
pub fn Money::is_negative(self : Money) -> Bool {
  self.minor < 0
}

///|
/// 整数除法并按舍入策略取整：计算 numerator / denominator 的舍入结果。
/// 这是利率、摊销等后续模块共用的精度原语，全程避免浮点。
pub fn round_div(
  numerator : Int,
  denominator : Int,
  mode : RoundMode,
) -> Int {
  if denominator <= 0 {
    abort("round_div: denominator must be positive")
  }
  let q = numerator / denominator
  let r = numerator % denominator
  let abs_r = if r < 0 { -r } else { r }
  match mode {
    Down => q
    Up =>
      if r == 0 {
        q
      } else if numerator >= 0 {
        q + 1
      } else {
        q - 1
      }
    HalfUp =>
      if abs_r * 2 >= denominator {
        if numerator >= 0 {
          q + 1
        } else {
          q - 1
        }
      } else {
        q
      }
    HalfEven => {
      let twice = abs_r * 2
      if twice > denominator {
        if numerator >= 0 {
          q + 1
        } else {
          q - 1
        }
      } else if twice < denominator {
        q
      } else if q % 2 == 0 {
        q
      } else if numerator >= 0 {
        q + 1
      } else {
        q - 1
      }
    }
  }
}

///|
/// 将金额舍入到指定小数位（0 元 / 1 角 / 2 分）。
pub fn Money::round_to(
  self : Money,
  decimals : Int,
  mode : RoundMode,
) -> Money {
  let unit = if decimals >= 2 {
    1
  } else if decimals == 1 {
    10
  } else {
    100
  }
  let v = round_div(self.minor, unit, mode) * unit
  { minor: v, currency: self.currency }
}

///|
/// 将金额格式化为带千分位与两位小数的字符串，如 `12,345.67`。
pub fn Money::format(self : Money) -> String {
  let abs = if self.minor < 0 { -self.minor } else { self.minor }
  let yuan = abs / 100
  let fen = abs % 100
  let sign = if self.minor < 0 { "-" } else { "" }
  sign + group_thousands(yuan) + "." + frac_to_2(fen)
}

///|
/// 千分位分组：1234567 -> "1,234,567"。
fn group_thousands(n : Int) -> String {
  if n == 0 {
    return "0"
  }
  let mut result = ""
  let mut x = n
  let mut first = true
  while x > 0 {
    let group = x % 1000
    x = x / 1000
    let group_str = if x > 0 {
      pad_to_3(group)
    } else {
      group.to_string()
    }
    if first {
      result = group_str
      first = false
    } else {
      result = group_str + "," + result
    }
  }
  result
}

///|
/// 把 [0, 999] 的整数补足为三位字符串。
fn pad_to_3(n : Int) -> String {
  if n < 10 {
    "00" + n.to_string()
  } else if n < 100 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
/// 把 [0, 99] 的"分"补足为两位字符串。
fn frac_to_2(n : Int) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}
