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

// 资本预算：净现值与内部收益率
let cf = [-1000.0, 300.0, 400.0, 500.0]
let npv = net_present_value(0.10, cf)
let irr = internal_rate_of_return(cf)
```

### 货币 API 约定

`Money::of(minor, currency)` 和 `Money::zero(currency)` 接受大写 ISO 4217 代码，金额始终是该币种的整数最小单位。当前支持 CNY、USD、EUR、GBP（2 位小数），JPY、KRW、VND（0 位），KWD、BHD、OMR、JOD、TND（3 位）。`currency_decimals(code)` 返回受支持币种的小数位数。其他代码（包括大小写错误）会中止；当前未提供汇率转换。

`Money::add` 和 `Money::sub` 仅允许相同币种，币种不一致时中止。`Money::round_to(decimals, mode)` 要求 `decimals` 在 0 到该币种的小数位数之间，超出范围时中止。金额运算结果超出 `Int` 范围时也会中止。`Money::format()` 按该币种的小数位数显示金额并添加千分位。`minor()` 和 `currency()` 返回金额的只读字段；请通过构造函数创建金额。

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
