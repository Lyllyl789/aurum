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
/// 返回向零截断策略（负数不按数学 floor 取整）。
pub fn round_down() -> RoundMode {
  Down
}

///|
/// 返回远离零取整策略（负数不按数学 ceil 取整）。
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
  match currency_decimals_option(currency) {
    Some(decimals) => decimals
    None => abort("unsupported currency: " + currency)
  }
}

///|
fn currency_decimals_option(currency : String) -> Int? {
  match currency {
    "JPY" | "KRW" | "VND" => Some(0)
    "CNY" | "USD" | "EUR" | "GBP" => Some(2)
    "KWD" | "BHD" | "OMR" | "JOD" | "TND" => Some(3)
    _ => None
  }
}

///|
/// 以最小货币单位构造金额。
pub fn Money::of(minor : Int, currency : String) -> Money {
  ignore(currency_decimals(currency))
  { minor, currency, }
}

///|
/// Fallible counterpart to `Money::of`; unsupported currency codes return None.
pub fn Money::try_of(minor : Int, currency : String) -> Money? {
  match currency_decimals_option(currency) {
    Some(_) => Some({ minor, currency, })
    None => None
  }
}

///|
/// Parses an ungrouped decimal amount exactly at the currency's minor-unit
/// precision. Extra fractional digits are accepted only when all are zero.
/// The input must use ASCII digits and `.`; whitespace, grouping and exponents
/// are not accepted. Unsupported currencies and Int-range overflow return None.
pub fn Money::parse(text : String, currency : String) -> Money? {
  parse_money_text(text, currency, round_half_even(), false)
}

///|
/// Parses a decimal amount and rounds discarded fractional digits according to
/// `mode`. This is explicit so callers cannot accidentally lose precision by
/// using the exact parser for over-precise input.
pub fn Money::parse_rounded(
  text : String,
  currency : String,
  mode : RoundMode,
) -> Money? {
  parse_money_text(text, currency, mode, true)
}

///|
fn parse_money_text(
  text : String,
  currency : String,
  mode : RoundMode,
  allow_rounding : Bool,
) -> Money? {
  let decimals = match currency_decimals_option(currency) {
    Some(value) => value
    None => return None
  }
  let chars = text.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut index = 0
  let negative = chars[0] == '-'
  if negative || chars[0] == '+' {
    index = 1
  }
  if index == chars.length() {
    return None
  }
  let mut factor = 1L
  for _ in 0..<decimals {
    factor = factor * 10L
  }
  let max_whole = 2147483648L / factor
  let mut whole = 0L
  let mut fraction = 0L
  let mut fraction_digits = 0
  let mut has_decimal = false
  let mut has_whole_digit = false
  let mut has_fraction_digit = false
  let mut first_discarded = -1
  let mut later_discarded_nonzero = false
  let mut i = index
  while i < chars.length() {
    let ch = chars[i]
    if ch == '.' {
      if has_decimal {
        return None
      }
      has_decimal = true
    } else {
      let code = ch.to_int()
      if code < '0'.to_int() || code > '9'.to_int() {
        return None
      }
      let digit = (code - '0'.to_int()).to_int64()
      if has_decimal {
        has_fraction_digit = true
        if fraction_digits < decimals {
          fraction = fraction * 10L + digit
          fraction_digits = fraction_digits + 1
        } else if first_discarded < 0 {
          first_discarded = digit.to_int()
        } else if digit != 0L {
          later_discarded_nonzero = true
        }
      } else {
        has_whole_digit = true
        if whole > max_whole / 10L || whole * 10L + digit > max_whole {
          return None
        }
        whole = whole * 10L + digit
      }
    }
    i = i + 1
  }
  if !has_whole_digit || (has_decimal && !has_fraction_digit) {
    return None
  }
  while fraction_digits < decimals {
    fraction = fraction * 10L
    fraction_digits = fraction_digits + 1
  }
  let mut magnitude = whole * factor + fraction
  let discarded_nonzero = first_discarded > 0 || later_discarded_nonzero
  if !allow_rounding && discarded_nonzero {
    return None
  }
  let increment = if first_discarded < 0 {
    false
  } else {
    match mode {
      Down => false
      Up => discarded_nonzero
      HalfUp => first_discarded >= 5
      HalfEven =>
        first_discarded > 5 ||
        (
          first_discarded == 5 &&
          (later_discarded_nonzero || magnitude % 2L != 0L)
        )
    }
  }
  if increment {
    magnitude = magnitude + 1L
  }
  let value = if negative { -magnitude } else { magnitude }
  if value < -2147483648L || value > 2147483647L {
    return None
  }
  Some({ minor: value.to_int(), currency, })
}

///|
/// 构造零金额。
pub fn Money::zero(currency : String) -> Money {
  Money::of(0, currency)
}

///|
fn checked_money(value : Int64, currency : String) -> Money {
  match try_money(value, currency) {
    Some(money) => money
    None => abort("Money: result out of Int range")
  }
}

///|
fn try_money(value : Int64, currency : String) -> Money? {
  match currency_decimals_option(currency) {
    None => None
    Some(_) =>
      if value < -2147483648L || value > 2147483647L {
        None
      } else {
        Some({ minor: value.to_int(), currency, })
      }
  }
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
/// Fallible same-currency addition. Returns None for a currency mismatch or
/// when the result exceeds the supported Int minor-unit range.
pub fn Money::try_add(self : Money, other : Money) -> Money? {
  if self.currency != other.currency {
    return None
  }
  try_money(self.minor.to_int64() + other.minor.to_int64(), self.currency)
}

///|
/// Fallible same-currency subtraction.
pub fn Money::try_sub(self : Money, other : Money) -> Money? {
  if self.currency != other.currency {
    return None
  }
  try_money(self.minor.to_int64() - other.minor.to_int64(), self.currency)
}

///|
/// Fallible negation; the minimum Int amount has no representable positive peer.
pub fn Money::try_neg(self : Money) -> Money? {
  try_money(-self.minor.to_int64(), self.currency)
}

///|
/// Fallible absolute value; returns None for the minimum Int amount.
pub fn Money::abs(self : Money) -> Money? {
  let value = self.minor.to_int64()
  try_money(if value < 0L { -value } else { value }, self.currency)
}

///|
/// Fallible integer scaling counterpart to `scale`.
pub fn Money::try_scale(self : Money, factor : Int) -> Money? {
  try_money(self.minor.to_int64() * factor.to_int64(), self.currency)
}

///|
/// Compares two same-currency amounts. Returns None instead of aborting when
/// the currencies differ.
pub fn Money::try_compare(self : Money, other : Money) -> Int? {
  if self.currency != other.currency {
    return None
  }
  if self.minor < other.minor {
    Some(-1)
  } else if self.minor > other.minor {
    Some(1)
  } else {
    Some(0)
  }
}

///|
/// Converts to a major-unit Double for approximate formulas. This conversion
/// is not a substitute for exact Money arithmetic.
pub fn Money::to_major_double(self : Money) -> Double {
  let factor = @math.pow(10.0, currency_decimals(self.currency).to_double())
  self.minor.to_double() / factor
}

///|
/// Returns an ungrouped, fixed-precision decimal string suitable for storage
/// or parsing. Unlike `format`, this output contains no thousands separators.
pub fn Money::to_decimal_string(self : Money) -> String {
  let digits = currency_decimals(self.currency)
  let mut factor = 1L
  for _ in 0..<digits {
    factor = factor * 10L
  }
  let value = self.minor.to_int64()
  let magnitude = if value < 0L { -value } else { value }
  let sign = if value < 0L { "-" } else { "" }
  let whole = magnitude / factor
  if digits == 0 {
    sign + whole.to_string()
  } else {
    let fraction = magnitude % factor
    let mut fraction_text = fraction.to_string()
    while fraction_text.length() < digits {
      fraction_text = "0" + fraction_text
    }
    sign + whole.to_string() + "." + fraction_text
  }
}

///|
/// Returns `self / denominator` as a dimensionless estimate for two
/// same-currency amounts. Zero denominator or currency mismatch returns None.
pub fn Money::ratio_to(self : Money, denominator : Money) -> Double? {
  if self.currency != denominator.currency || denominator.minor == 0 {
    return None
  }
  Some(self.minor.to_double() / denominator.minor.to_double())
}

///|
/// Sums same-currency values exactly. An empty array returns zero in the
/// requested currency; a currency mismatch or range overflow returns None.
pub fn Money::sum(values : Array[Money], currency : String) -> Money? {
  if currency_decimals_option(currency) == None {
    return None
  }
  let mut total = 0L
  for value in values {
    if value.currency() != currency {
      return None
    }
    total = total + value.minor().to_int64()
  }
  try_money(total, currency)
}

///|
/// Multiplies an amount by an integer ratio and rounds once, without converting
/// the amount to binary floating point. The denominator must be positive.
pub fn Money::scale_ratio(
  self : Money,
  numerator : Int,
  denominator : Int,
  mode : RoundMode,
) -> Money? {
  if denominator <= 0 {
    return None
  }
  let product = self.minor.to_int64() * numerator.to_int64()
  let value = round_div_int64(product, denominator.to_int64(), mode)
  if value < -2147483648L || value > 2147483647L {
    return None
  }
  Some({ minor: value.to_int(), currency: self.currency, })
}

///|
fn round_div_int64(
  numerator : Int64,
  denominator : Int64,
  mode : RoundMode,
) -> Int64 {
  let q = numerator / denominator
  let r = numerator % denominator
  let abs_r = if r < 0L { -r } else { r }
  let twice = abs_r * 2L
  match mode {
    Down => q
    Up => if r == 0L { q } else if numerator >= 0L { q + 1L } else { q - 1L }
    HalfUp =>
      if twice >= denominator {
        if numerator >= 0L {
          q + 1L
        } else {
          q - 1L
        }
      } else {
        q
      }
    HalfEven =>
      if twice > denominator {
        if numerator >= 0L {
          q + 1L
        } else {
          q - 1L
        }
      } else if twice < denominator || q % 2L == 0L {
        q
      } else if numerator >= 0L {
        q + 1L
      } else {
        q - 1L
      }
  }
}

///|
/// Splits an amount equally into `parts` pieces. Any leftover minor units are
/// assigned one at a time to the earliest pieces, so the results sum exactly
/// to the original amount. Returns None when `parts` is not positive.
pub fn Money::allocate_equal(self : Money, parts : Int) -> Array[Money]? {
  if parts <= 0 {
    return None
  }
  let quotient = self.minor / parts
  let remainder = self.minor % parts
  let residual_count = if remainder < 0 { -remainder } else { remainder }
  let residual_sign = if remainder < 0 { -1 } else { 1 }
  let result = Array::make(parts, Money::zero(self.currency))
  let mut i = 0
  while i < parts {
    let extra = if i < residual_count { residual_sign } else { 0 }
    result[i] = Money::of(quotient + extra, self.currency)
    i = i + 1
  }
  Some(result)
}

///|
priv struct AllocationRemainder {
  index : Int
  remainder : Int64
}

///|
fn remainder_has_priority(
  a : AllocationRemainder,
  b : AllocationRemainder,
) -> Bool {
  a.remainder > b.remainder || (a.remainder == b.remainder && a.index < b.index)
}

///|
fn swap_remainders(
  items : Array[AllocationRemainder],
  a : Int,
  b : Int,
) -> Unit {
  let temp = items[a]
  items[a] = items[b]
  items[b] = temp
}

///|
fn sift_remainders_down(
  items : Array[AllocationRemainder],
  root : Int,
  end : Int,
) -> Unit {
  let mut parent = root
  while true {
    let left = parent * 2 + 1
    if left >= end {
      return
    }
    let right = left + 1
    let child = if right < end &&
      remainder_has_priority(items[right], items[left]) {
      right
    } else {
      left
    }
    if remainder_has_priority(items[child], items[parent]) {
      swap_remainders(items, parent, child)
      parent = child
    } else {
      return
    }
  }
}

///|
fn sort_remainders_ascending(items : Array[AllocationRemainder]) -> Unit {
  let mut start = items.length() / 2 - 1
  while start >= 0 {
    sift_remainders_down(items, start, items.length())
    start = start - 1
  }
  let mut end = items.length() - 1
  while end > 0 {
    swap_remainders(items, 0, end)
    sift_remainders_down(items, 0, end)
    end = end - 1
  }
}

///|
/// Allocates an amount proportionally using integer weights and the
/// largest-remainder method. Weights must be nonnegative with a positive sum.
/// Ties go to the lower input index; results always sum exactly to `self`.
pub fn Money::allocate_by_weights(
  self : Money,
  weights : Array[Int],
) -> Array[Money]? {
  if weights.length() == 0 {
    return None
  }
  let mut total_weight = 0L
  for weight in weights {
    if weight < 0 {
      return None
    }
    total_weight = total_weight + weight.to_int64()
  }
  if total_weight == 0L {
    return None
  }
  let amount = self.minor.to_int64()
  let negative = amount < 0L
  let magnitude = if negative { -amount } else { amount }
  let shares = Array::make(weights.length(), 0L)
  let records = Array::make(weights.length(), { index: 0, remainder: 0L, })
  let mut allocated = 0L
  let mut i = 0
  while i < weights.length() {
    let numerator = magnitude * weights[i].to_int64()
    let share = numerator / total_weight
    shares[i] = share
    allocated = allocated + share
    records[i] = { index: i, remainder: numerator % total_weight, }
    i = i + 1
  }
  sort_remainders_ascending(records)
  let mut left = (magnitude - allocated).to_int()
  while left > 0 {
    let index = records[records.length() - left].index
    shares[index] = shares[index] + 1L
    left = left - 1
  }
  let zero = Money::zero(self.currency)
  let result = Array::make(weights.length(), zero)
  i = 0
  while i < weights.length() {
    let value = if negative { -shares[i] } else { shares[i] }
    if value < -2147483648L || value > 2147483647L {
      return None
    }
    result[i] = Money::of(value.to_int(), self.currency)
    i = i + 1
  }
  Some(result)
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
  let twice = abs_r.to_int64() * 2L
  match mode {
    Down => q
    Up => if r == 0 { q } else if numerator >= 0 { q + 1 } else { q - 1 }
    HalfUp =>
      if twice >= denominator.to_int64() {
        if numerator >= 0 {
          q + 1
        } else {
          q - 1
        }
      } else {
        q
      }
    HalfEven =>
      if twice > denominator.to_int64() {
        if numerator >= 0 {
          q + 1
        } else {
          q - 1
        }
      } else if twice < denominator.to_int64() {
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
