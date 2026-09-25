// Copyright 2026 Aurum Authors
// Licensed under Apache-2.0
//
// 精确金额：以币种的最小货币单位为存储基础的整数运算。
// 金融计算中，二进制浮点会引入 0.1 + 0.2 != 0.3 一类的误差，
// 因此 Aurum 的金额运算使用整数最小单位，避免二进制浮点误差。

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
/// 精确金额，以币种的最小货币单位 `minor` 存储。
/// `currency` 必须是 currency_decimals 支持的 ISO 4217 代码。
pub struct Money {
  priv minor : Int
  priv currency : String
} derive(Debug, Eq)

///|
/// 返回以最小货币单位表示的整数金额。
pub fn Money::minor(self : Money) -> Int {
  self.minor
}

///|
/// 返回金额的币种代码。
pub fn Money::currency(self : Money) -> String {
  self.currency
}

///|
/// 返回受支持币种的 ISO 4217 小数位数；未知或非法代码会中止。
/// 支持 CNY、USD、EUR、GBP（2 位），JPY、KRW、VND（0 位），
/// KWD、BHD、OMR、JOD、TND（3 位）。
pub fn currency_decimals(currency : String) -> Int {
  match currency {
    "JPY" | "KRW" | "VND" => 0
    "CNY" | "USD" | "EUR" | "GBP" => 2
    "KWD" | "BHD" | "OMR" | "JOD" | "TND" => 3
    _ => abort("unsupported currency: " + currency)
  }
}

///|
/// 以最小货币单位构造金额。
pub fn Money::of(minor : Int, currency : String) -> Money {
  ignore(currency_decimals(currency))
  { minor, currency, }
}

///|
/// 构造零金额。
pub fn Money::zero(currency : String) -> Money {
  Money::of(0, currency)
}

///|
fn checked_money(value : Int64, currency : String) -> Money {
  if value < -2147483648L || value > 2147483647L {
    abort("Money: result out of Int range")
  }
  { minor: value.to_int(), currency, }
}

///|
/// 金额相加；币种不一致时中止。
pub fn Money::add(self : Money, other : Money) -> Money {
  if self.currency != other.currency {
    abort("Money::add: currency mismatch")
  }
  checked_money(self.minor.to_int64() + other.minor.to_int64(), self.currency)
}

///|
/// 金额相减；币种不一致时中止。
pub fn Money::sub(self : Money, other : Money) -> Money {
  if self.currency != other.currency {
    abort("Money::sub: currency mismatch")
  }
  checked_money(self.minor.to_int64() - other.minor.to_int64(), self.currency)
}

///|
/// 取相反数。
pub fn Money::neg(self : Money) -> Money {
  checked_money(-self.minor.to_int64(), self.currency)
}

///|
/// 按整数倍缩放金额（乘以标量）。
pub fn Money::scale(self : Money, factor : Int) -> Money {
  checked_money(self.minor.to_int64() * factor.to_int64(), self.currency)
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
pub fn round_div(numerator : Int, denominator : Int, mode : RoundMode) -> Int {
  if denominator <= 0 {
    abort("round_div: denominator must be positive")
  }
  let q = numerator / denominator
  let r = numerator % denominator
  let abs_r = if r < 0 { -r } else { r }
  match mode {
    Down => q
    Up => if r == 0 { q } else if numerator >= 0 { q + 1 } else { q - 1 }
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
/// 将金额舍入到指定小数位，范围为 0 到该币种的小数位数。
pub fn Money::round_to(self : Money, decimals : Int, mode : RoundMode) -> Money {
  let currency_digits = currency_decimals(self.currency)
  if decimals < 0 || decimals > currency_digits {
    abort("Money::round_to: decimals out of range")
  }
  let mut unit = 1
  for _ in decimals..<currency_digits {
    unit = unit * 10
  }
  let v = round_div(self.minor, unit, mode).to_int64() * unit.to_int64()
  checked_money(v, self.currency)
}

///|
/// 按币种小数位数格式化金额，并为整数部分添加千分位。
pub fn Money::format(self : Money) -> String {
  let digits = currency_decimals(self.currency)
  let mut factor = 1L
  for _ in 0..<digits {
    factor = factor * 10L
  }
  let amount = self.minor.to_int64()
  let abs = if amount < 0L { -amount } else { amount }
  let major = abs / factor
  let fraction = abs % factor
  let sign = if self.minor < 0 { "-" } else { "" }
  if digits == 0 {
    sign + group_thousands(major)
  } else {
    let mut padded = fraction.to_string()
    while padded.length() < digits {
      padded = "0" + padded
    }
    sign + group_thousands(major) + "." + padded
  }
}

///|
/// 千分位分组：1234567 -> "1,234,567"。
fn group_thousands(n : Int64) -> String {
  if n == 0 {
    return "0"
  }
  let mut result = ""
  let mut x = n
  let mut first = true
  while x > 0 {
    let group = x % 1000L
    x = x / 1000L
    let group_str = if x > 0 { pad_to_3(group) } else { group.to_string() }
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
fn pad_to_3(n : Int64) -> String {
  if n < 10 {
    "00" + n.to_string()
  } else if n < 100 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}
