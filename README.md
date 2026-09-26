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
- **货币时间价值**：现值、终值、年金、永续年金
- **资本预算**：NPV、IRR、回收期、盈利指数
- **贷款摊销**：等额本息 / 等额本金还款计划
- **固定资产折旧**：直线法、双倍余额递减、年数总和、工作量法
- **债券定价**：价格、到期收益率、久期与凸性
- **财务比率**：流动性、偿债、盈利、营运与估值指标
- **多币种**：ISO 4217 元数据与汇率换算

## 目录结构

```
aurum/
├── lib/                 # 核心库
│   ├── money/           # 精确金额与舍入
│   ├── tvm/             # 货币时间价值
│   ├── capital/         # 资本预算
│   ├── amortize/        # 贷款摊销
│   ├── wear/            # 固定资产折旧
│   ├── bond/            # 债券定价
│   ├── ratio/           # 财务比率
│   └── currency/        # 多币种与汇率
├── bin/                 # 命令行演示
├── notes/               # 设计笔记
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
let payback = payback_period(cf)
// 三者均为 Double?；请通过 match 处理 Some(value) / None
```

### 货币 API 约定

`Money::of(minor, currency)` 和 `Money::zero(currency)` 接受大写 ISO 4217 代码，金额始终是该币种的整数最小单位。当前支持 CNY、USD、EUR、GBP（2 位小数），JPY、KRW、VND（0 位），KWD、BHD、OMR、JOD、TND（3 位）。`currency_decimals(code)` 返回受支持币种的小数位数。其他代码（包括大小写错误）会中止；当前未提供汇率转换。

`Money::add` 和 `Money::sub` 仅允许相同币种，币种不一致时中止。`Money::round_to(decimals, mode)` 要求 `decimals` 在 0 到该币种的小数位数之间，超出范围时中止。金额运算结果超出 `Int` 范围时也会中止。`Money::format()` 按该币种的小数位数显示金额并添加千分位。`minor()` 和 `currency()` 返回金额的只读字段；请通过构造函数创建金额。

### TVM API 约定

`future_value`、`present_value`、普通/期初年金与永续年金函数均返回 `Double?`。`Some(value)` 表示有限数值的估算结果；`None` 表示非法输入或计算得到 NaN/Infinity，不会因这些输入直接中止。调用方须处理 `None`。

金额、利率及增长率必须为有限数值（非 NaN/Infinity）。有限期函数要求 `periods >= 0`、`rate > -1`；零期的单笔现金流等于原金额，零期年金为零。有限期可使用负利率，只要大于 -1；零利率年金按 `payment × periods` 计算。普通永续年金要求 `rate > 0`；增长永续年金要求 `rate > growth > -1`。计算结果若超出 `Double` 可表示的有限范围，返回 `None`。

TVM 使用 IEEE-754 `Double` 复利计算，适合估算，不保证分级精度、十进制精确性或极端参数下的相对误差。浮点下溢可能得到零；利率接近零时，年金公式使用 `ln_1p`/`expm1` 减少抵消误差。需要精确货币金额时，请单独确定舍入规则，并用 `money` 模块处理金额。

### 资本预算 API 约定

`net_present_value`、`internal_rate_of_return`、`internal_rate_of_return_in_range`、`payback_period`、`discounted_payback_period` 和 `profitability_index` 均返回 `Double?`。现金流数组不能为空，所有现金流与利率必须有限；折现率必须大于 -1。输入无效或计算出现非有限数值时返回 `None`。盈利指数还要求第 0 期现金流严格为负。

`internal_rate_of_return` 只对忽略零值后恰好发生一次符号变化的现金流报告唯一 IRR。多次符号变化的现金流可能有多个 IRR，因此保守地返回 `None`；即使特定现金流恰好只有一个实根，也不会猜测。无根、搜索区间不包含根或数值计算无法收敛时同样返回 `None`。默认搜索区间为 [-0.999999999999, 1e12]；`internal_rate_of_return_in_range(cashflows, lower, upper)` 可指定闭区间，要求 `-1 < lower < upper`。区间端点是根时可直接返回；其他情况通过端点异号后二分，最多 256 次迭代，区间宽度达到约 `1e-12 × (1 + |rate|)` 时返回近似值。超出默认区间的根可通过自定义区间求解。

两种回收期返回首次累计现金流非负的时间：第 0 期已经非负时为 `Some(0)`，期内按该期现金流线性插值。给定现金流期限内未回收时返回 `None`，不会把期限长度误作回收期。折现回收期按 `rate > -1` 的折现现金流累计。`None` 本身不区分未回收与输入错误，调用方应先校验输入以解释结果。

## 进度

- [x] `money` 精确金额与舍入
- [x] `tvm` 货币时间价值
- [x] `capital` 资本预算（NPV / IRR）
- [x] `amortize` 贷款摊销
- [x] `wear` 折旧
- [x] `bond` 债券定价
- [x] `ratio` 财务比率
- [x] `currency` 多币种与汇率

## 参考来源

本库的金融公式与数值方法均为独立编写，仅采用教科书级别的通用公式（属于不受版权保护的事实与算法）。主要参考如下公开领域知识：

- 货币时间价值、债券定价、贷款摊销与固定资产折旧的标准公式，来自通行的财务管理 / 金融数学教材（如 Ross《公司理财》、Brealey–Myers《公司财务原理》等公开教学大纲中的通用公式）。
- 内部收益率（IRR）与到期收益率（YTM）的二分法求根，以及「单符号变化判定唯一正根」的规则，来自数值分析与投资评估的通用做法。
- 年金公式以 `ln_1p` / `expm1` 替代朴素幂运算，以减少利率接近零时的抵消误差，参考数值计算的通行惯例。

代码不包含任何第三方实现；`money` 模块的整数最小单位运算与舍入原语为自行设计。

## 许可证

Apache-2.0
