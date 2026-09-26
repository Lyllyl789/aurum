# Aurum

> 精密的金融计算，如金般可靠。

Aurum 是一个用 [MoonBit](https://www.moonbitlang.com) 编写的金融数学与财务管理计算库，
覆盖货币金额、货币时间价值（TVM）、资本预算、摊销、折旧、债券定价与财务比率等核心场景。

## 为什么是 Aurum

金融计算最怕浮点误差——`0.1 + 0.2` 在二进制浮点里并不等于 `0.3`。
Aurum 的金额以币种对应的最小货币单位存储，用整数运算避免金额中的二进制浮点误差。

## 特性

- **精确金额**：按币种最小单位存储，支持 0、2、3 位小数币种
- **多种舍入策略**：四舍五入、银行家舍入、向上 / 向下取整
- **货币时间价值**：现值、终值、年金
- **资本预算**：NPV、IRR、回收期、盈利指数

## 目录结构

```
aurum/
├── lib/                 # 核心库
│   ├── money/           # 精确金额与舍入
│   ├── tvm/             # 货币时间价值
│   └── capital/         # 资本预算
├── bin/                 # 命令行演示
├── sample/              # 使用示例（规划中）
├── notes/               # 设计笔记（规划中）
└── moon.mod
```

## 使用

```moonbit
// 以 CNY 的最小货币单位（分）构造金额
let a = Money::of(12345, "CNY")  // 123.45 元
let b = Money::of(100, "CNY")    // 1.00 元

let total = a.add(b)             // 12445 分
println(total.format())          // 124.45

let yen = Money::of(1234, "JPY") // 1234 日元
println(yen.format())             // 1,234
let dinar = Money::of(1234, "KWD") // 1.234 科威特第纳尔
println(dinar.round_to(2, round_half_up()).format()) // 1.230

// 货币时间价值：10000 元按 5% 复利 10 年
let fv = future_value(10000.0, 0.05, 10)
// fv: Double?；Some(value) 是估算结果，None 表示输入无效或结果溢出

// 资本预算：净现值与内部收益率
let cf = [-1000.0, 300.0, 400.0, 500.0]
let npv = net_present_value(0.10, cf)
let irr = internal_rate_of_return(cf)
```

### 货币 API 约定

`Money::of(minor, currency)` 和 `Money::zero(currency)` 接受大写 ISO 4217 代码，金额始终是该币种的整数最小单位。当前支持 CNY、USD、EUR、GBP（2 位小数），JPY、KRW、VND（0 位），KWD、BHD、OMR、JOD、TND（3 位）。`currency_decimals(code)` 返回受支持币种的小数位数。其他代码（包括大小写错误）会中止；当前未提供汇率转换。

`Money::add` 和 `Money::sub` 仅允许相同币种，币种不一致时中止。`Money::round_to(decimals, mode)` 要求 `decimals` 在 0 到该币种的小数位数之间，超出范围时中止。金额运算结果超出 `Int` 范围时也会中止。`Money::format()` 按该币种的小数位数显示金额并添加千分位。`minor()` 和 `currency()` 返回金额的只读字段；请通过构造函数创建金额。

### TVM API 约定

`future_value`、`present_value`、普通/期初年金与永续年金函数均返回 `Double?`。`Some(value)` 表示有限数值的估算结果；`None` 表示非法输入或计算得到 NaN/Infinity，不会因这些输入直接中止。调用方须处理 `None`。

金额、利率及增长率必须为有限数值（非 NaN/Infinity）。有限期函数要求 `periods >= 0`、`rate > -1`；零期的单笔现金流等于原金额，零期年金为零。有限期可使用负利率，只要大于 -1；零利率年金按 `payment × periods` 计算。普通永续年金要求 `rate > 0`；增长永续年金要求 `rate > growth > -1`。计算结果若超出 `Double` 可表示的有限范围，返回 `None`。

TVM 使用 IEEE-754 `Double` 复利计算，适合估算，不保证分级精度、十进制精确性或极端参数下的相对误差。浮点下溢可能得到零；利率接近零时，年金公式使用 `ln_1p`/`expm1` 减少抵消误差。需要精确货币金额时，请单独确定舍入规则，并用 `money` 模块处理金额。

## 进度

- [x] `money` 精确金额与舍入
- [x] `tvm` 货币时间价值
- [x] `capital` 资本预算（NPV / IRR）
- [ ] `amortize` 贷款摊销
- [ ] `wear` 折旧
- [ ] `bond` 债券定价
- [ ] `ratio` 财务比率

## 许可证

Apache-2.0
