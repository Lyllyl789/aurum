# Aurum

> 金额使用整数最小单位，财务指标使用浮点估算。

Aurum 是一个用 [MoonBit](https://www.moonbitlang.com) 编写的基础金融计算库，重点验证 MoonBit 中金额表示、常见现金流公式和失败边界的清晰契约。

项目范围刻意限定为单币种最小单位金额、基础 TVM/资本预算计算和周期性贷款公式；折旧、债券、比率与外部汇率是小型公式模块示例，不构成完整会计系统或生产级估值平台。Aurum 不处理实时行情、日期日历、票息日程、收益率曲线、会计准则或法规校验，也不宣称替代 NumPy Financial、Python Decimal 或 QuantLib。功能边界、对标依据和可复现验收值见[对标与验收说明](notes/comparison-and-acceptance.md)。

## 为什么是 Aurum

`0.1 + 0.2` 在二进制浮点里并不精确等于 `0.3`。Aurum 的 `Money` 用币种最小单位的 `Int` 存储金额，避免金额加减中的这类表示误差；利率、汇率及其余财务指标仍使用 `Double` 估算，需要调用方决定舍入与业务校验规则。

## 特性

- **精确金额**：按币种最小单位存储；支持严格十进制字符串解析/序列化、显式舍入输入、失败可控运算、整数比例运算和等额/按权重分摊
- **多种舍入策略**：四舍五入、银行家舍入、向上 / 向下取整
- **货币时间价值**：现值、终值、年金、永续年金
- **资本预算**：NPV、IRR、回收期、盈利指数
- **贷款摊销**：浮点估算计划，以及按币种最小单位逐期舍入、末期结清的等额本息 / 等额本金计划
- **固定资产折旧**：直线法、双倍余额递减、年数总和、工作量法
- **债券定价**：价格、到期收益率、久期与凸性
- **财务比率**：流动性、偿债、盈利、营运与估值指标
- **多币种**：12 种币种的代码/小数位元数据与调用方提供汇率的换算

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

// 严格解析十进制金额，并按权重分摊，分摊结果的和保持精确
let invoice = Money::parse("100.00", "CNY") // Money?
let shares = match invoice {
  Some(value) => value.allocate_by_weights([1, 2, 3])
  None => None
} // Array[Money]?

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

// 10000.00 CNY，月利率 1%，12 期：逐期按分舍入，末期调整至余额归零
let schedule = equal_installment_money_schedule(
  Money::of(1000000, "CNY"),
  0.01,
  12,
  round_half_up(),
)
```

### 货币 API 约定

`Money::of(minor, currency)` 和 `Money::zero(currency)` 只接受当前列出的代码，金额始终是该币种的整数最小单位。当前支持 CNY、USD、EUR、GBP（2 位小数），JPY、KRW、VND（0 位），KWD、BHD、OMR、JOD、TND（3 位）；这不是完整 ISO 4217 数据库。`currency_decimals(code)` 返回受支持币种的小数位数。未知代码或大小写错误会中止，构造函数不返回 `Option`。

需要将外部十进制文本读入金额时，`Money::parse(text, currency)` 接受 ASCII 数字和 `.`，不接受空白、千分位或指数写法；超过币种精度的非零小数位返回 `None`，多出的零不改变金额。`Money::parse_rounded` 显式接受舍入模式。`Money::try_of` 是 `Money::of` 的非中止版本。`scale_ratio(numerator, denominator, mode)` 使用整数最小单位做比例计算，分母须为正，溢出返回 `None`。

`to_decimal_string()` 输出适合持久化和重新解析的固定精度、无千分位文本；`format()` 仍用于带千分位的展示。`try_add`、`try_sub`、`try_neg`、`abs`、`try_scale`、`try_compare` 和 `Money::sum` 提供可恢复的 `Option` 失败路径；金额/币种不匹配或最小单位溢出时返回 `None`。`to_major_double()` 与 `ratio_to()` 是方便估算的浮点桥接，不再保持整数金额的精确性。

`allocate_equal(parts)` 等额分摊，余数最小单位按顺序分给前面的份额；`allocate_by_weights(weights)` 使用最大余数法按非负整数权重分摊，余数并列时先给输入顺序靠前的份额。两种分摊都返回可加回原金额的精确金额数组；份数/权重无效时返回 `None`。

`Money::add` 和 `Money::sub` 仅允许相同币种，币种不一致时中止。`Money::round_to(decimals, mode)` 要求 `decimals` 在 0 到该币种的小数位数之间，超出范围时中止。`add`、`sub`、`neg`、`scale`、`round_to` 的结果超出 32 位 `Int` 范围时也会中止；`round_div` 要求正分母，否则中止。这些是 `Money` 的边界契约，不能概括为“所有非法输入返回 `None`”。`Money::format()` 按该币种的小数位数显示金额并添加千分位。`minor()` 和 `currency()` 返回金额的只读字段。

`round_down()` 对负数向零截断，`round_up()` 对负数远离零；这两个名称沿用现有 API，**不表示**数学意义的 floor/ceil。半向上在恰好一半时远离零，银行家舍入在恰好一半时取偶数。`round_div` 的余数比较使用更宽整数，避免大分母下的中间溢出。

### TVM API 约定

`future_value`、`present_value`、普通/期初年金与永续年金函数均返回 `Double?`。`Some(value)` 表示有限数值的估算结果；`None` 表示非法输入或计算得到 NaN/Infinity，不会因这些输入直接中止。调用方须处理 `None`。

金额、利率及增长率必须为有限数值（非 NaN/Infinity）。有限期函数要求 `periods >= 0`、`rate > -1`；零期的单笔现金流等于原金额，零期年金为零。有限期可使用负利率，只要大于 -1；零利率年金按 `payment × periods` 计算。普通永续年金要求 `rate > 0`；增长永续年金要求 `rate > growth > -1`。计算结果若超出 `Double` 可表示的有限范围，返回 `None`。

TVM 使用 IEEE-754 `Double` 复利计算，适合估算，不保证分级精度、十进制精确性或极端参数下的相对误差。浮点下溢可能得到零；利率接近零时，年金公式使用 `ln_1p`/`expm1` 减少抵消误差。需要精确货币金额时，请单独确定舍入规则，并用 `money` 模块处理金额。

`effective_annual_rate(nominal, periods_per_year)` 将名义年利率换算为有效年利率；`nominal_annual_rate_from_effective(effective, periods_per_year)` 做反向换算。两者把利率作为小数传入（如 `0.12` 表示 12%），只处理等间隔复利，不表示实际合同 APR、费用或日计数约定。

### 资本预算 API 约定

`net_present_value`、`internal_rate_of_return`、`internal_rate_of_return_in_range`、`payback_period`、`discounted_payback_period` 和 `profitability_index` 均返回 `Double?`。现金流数组不能为空，所有现金流与利率必须有限；折现率必须大于 -1。输入无效或计算出现非有限数值时返回 `None`。盈利指数还要求第 0 期现金流严格为负。

`internal_rate_of_return` 只对忽略零值后恰好发生一次符号变化的现金流报告唯一 IRR。多次符号变化的现金流可能有多个 IRR，因此保守地返回 `None`；即使特定现金流恰好只有一个实根，也不会猜测。无根、搜索区间不包含根或数值计算无法收敛时同样返回 `None`。默认搜索区间为 [-0.999999999999, 1e12]；`internal_rate_of_return_in_range(cashflows, lower, upper)` 可指定闭区间，要求 `-1 < lower < upper`。区间端点是根时可直接返回；其他情况通过端点异号后二分，最多 256 次迭代，区间宽度达到约 `1e-12 × (1 + |rate|)` 时返回近似值。超出默认区间的根可通过自定义区间求解。

两种回收期返回首次累计现金流非负的时间：第 0 期已经非负时为 `Some(0)`，期内按该期现金流线性插值。给定现金流期限内未回收时返回 `None`，不会把期限长度误作回收期。折现回收期按 `rate > -1` 的折现现金流累计。`None` 本身不区分未回收与输入错误，调用方应先校验输入以解释结果。

### 其余模块的返回边界

| 模块 | 当前实现的返回与校验 |
| --- | --- |
| `amortize` | 浮点 API 要求有限本金、每期利率大于 -1、期数大于 0；返回 `Double?` 或 `Array[Payment]?`。`Money` 计划要求正本金、非负每期利率，利息逐期按指定舍入模式到币种最小单位；可传入可选额外本金，提前结清后的行置零，最后一个非零还款调整为结清余额。`summarize_money_schedule` 校验期号、币种、逐期加总和余额衔接，并汇总本金/利息/还款。 |

`capital.discounted_cash_flow_schedule(rate, cashflows)` 返回 NPV 的逐期现值分解，期号从 0 开始，便于审计每项折现贡献；只需要合计时继续使用不分配明细数组的 `net_present_value`。
| `wear` | 成本与残值须有限，使用年限须大于 0；逐年函数的年份须在 1 到使用年限内，工作量法的总工作量须有限且大于 0、当期工作量须有限。结果非有限返回 `None`。当前未强制成本、残值和工作量的财务业务关系；调用方须自行确认残值不高于成本及当期工作量的业务范围。 |
| `bond` | 票息、面值、收益率或市价中实际使用的输入须有限，期数须大于 0；定价依赖 `tvm` 的 `rate > -1` 约束。零价格使久期/凸性返回 `None`；到期收益率在实现的搜索范围内无法括根或计算失败也返回 `None`。 |
| `ratio` | 任一参与计算的输入非有限、分母为 0 或比值非有限时返回 `None`。它不检查各指标的财务业务关系。 |
| `currency` | `lookup` 只查询上述 12 种币种，未知代码返回 `None`。`cross_rate` 要求两个正且有限的外部汇率，乘积非有限时返回 `None`。`convert` 要求正且有限的外部 `rate` 与受支持目标币种；非有限或舍入后超出 `Int` 范围的结果返回 `None`。 |

### 最小单位贷款计划

`equal_installment_money_schedule` 和 `equal_principal_money_schedule` 直接接收 `Money` 本金，并要求正本金、非负每期利率和正期数。每期利息按调用方选择的 `RoundMode` 舍入到最小单位；等额本金的除不尽余数并入最后一期本金，等额本息因利息/月供舍入可能提前结清，提前结清后剩余期次为零。最后一个非零还款以剩余本金为准，确保余额精确归零。两种函数均返回 `Array[MoneyPayment]?`；输入无效、结果溢出时为 `None`。金额仍受 `Money` 的 32 位最小单位范围约束。

`summarize_money_schedule` 对生成的完整计划执行逐期对账：期号连续、币种统一、还款等于本金加利息、余额逐期衔接；一致时返回本金、利息、总还款和期末余额。汇总字段自身超出 `Money` 范围时返回 `None`。

`currency.convert(amount, target, rate)` 中的 `rate` 由调用方输入，含义为 1 单位源币种对应的目标币种数量；库不获取实时行情。换算经过 `Double`，再按 half-up 舍入到目标币种最小单位，不承诺十进制精确汇率计算。源金额须先通过 `Money::of` 构造，其未知币种错误属于上述 `Money` 中止契约。

## 进度

- [x] `money` 精确金额与舍入
- [x] `tvm` 货币时间价值
- [x] `capital` 资本预算（NPV / IRR）
- [x] `amortize` 贷款摊销
- [x] `wear` 折旧
- [x] `bond` 债券定价
- [x] `ratio` 财务比率
- [x] `currency` 有限币种元数据与外部汇率换算

## 规范、对标与复核记录

- **设计规范**：[设计笔记](notes/design.md) 详细记录了各模块实现边界与数值精度策略。
- **AI 辅助边界与人工复核记录**：[notes/ai-review.md](notes/ai-review.md) 完整记录 AI 辅助范围、权责边界与项目负责人的人工核验记录（已完成全部复核闭环确认）。
- **过程开发记录**：[开发记录](notes/development-log.md) 记录了各阶段边界强化、测试补齐与持续集成的真实执行结果。
- **范围与验收说明**：[对标与验收说明](notes/comparison-and-acceptance.md) 记录了项目功能范围、成熟工具功能矩阵对照、差异说明和固定可复现验收值。

## 参考来源

本项目为原创开源基础库，核心数学模型参考通行的财务管理与数值计算公开知识：

- 货币时间价值、债券定价、贷款摊销与固定资产折旧的标准公式，来自通行的财务管理 / 金融数学教材（如 Ross《公司理财》、Brealey–Myers《公司财务原理》等公开教学大纲中的通用公式）。
- 内部收益率（IRR）与到期收益率（YTM）的二分法求根，以及「单符号变化判定唯一正根」的规则，来自数值分析与投资评估的通用做法。
- 年金公式以 `ln_1p` / `expm1` 替代朴素幂运算，以减少利率接近零时的抵消误差，参考数值计算的通行惯例。

## 许可证

Apache-2.0
