# Aurum

> 金额使用整数最小单位，财务指标使用浮点估算。

Aurum 是一个用 [MoonBit](https://www.moonbitlang.com) 编写的基础金融计算库，重点验证 MoonBit 中金额表示、常见现金流公式和失败边界的清晰契约。

项目范围刻意限定为单币种最小单位金额、基础 TVM/资本预算计算和周期性贷款公式；折旧、债券、比率与外部汇率是小型公式模块示例，不构成完整会计系统或生产级估值平台。Aurum 不处理实时行情、日期日历、票息日程、收益率曲线、会计准则或法规校验，也不宣称替代 NumPy Financial、Python Decimal 或 QuantLib。功能边界、对标依据和可复现回归值见[功能对照与回归验证](notes/comparison-and-acceptance.md)。

## 版本演进与维护范围

以下按提交区分九月已有能力和十月维护改进，便于使用者核对功能来源及数值行为。

- **九月已有基础**：以 [2026-09-30 的 `8e9cd48`](https://github.com/Lyllyl789/aurum/commit/8e9cd48b95d8102589d87131572ae58406263a92) 为代码比较基线。下列八个模块及金额解析/分摊、名义/有效年利率换算、NPV 逐期明细、按最小单位舍入的贷款计划和摘要对账均已存在，属于项目累计能力。
- **十月已完成改进**：[`9c62fe2`](https://github.com/Lyllyl789/aurum/commit/9c62fe2363512c61d6108738e8c59b0e0ab3ee3b) 为现有 NPV 合计加入 Neumaier 补偿求和，新增一项抵消现金流回归测试及对应 CLI 演示，并更新说明；这是数值稳定性维护，不是首次实现资本预算模块。
- **场景与复现**：十月增加三个固定输入的串联示例和完整导入示例，分别展示金额分摊、现金流估算和还款计划；这些是合成样例，不代表真实用户反馈或业务效果。

功能边界、版本差异和验证方式见[功能范围与版本记录](notes/season-plan.md)；固定输入的使用示例见[使用场景说明](notes/use-cases.md)。

## 为什么是 Aurum

`0.1 + 0.2` 在二进制浮点里并不精确等于 `0.3`。Aurum 的 `Money` 用币种最小单位的 `Int` 存储金额，避免金额加减中的这类表示误差；利率、汇率及其余财务指标仍使用 `Double` 估算，需要调用方决定舍入与业务校验规则。

MoonBit 生态已有十进制数值、固定收益现金流、整数贷款和会计报表等相邻实现。Aurum 的用途是为教学与测算原型串联有限范围的币种金额分摊、等间隔现金流估算和按最小单位舍入的还款计划；它不提供任意精度十进制、日期/曲线建模、会计账簿或风险模拟。具体交集、输入和数值模型差异见 [MoonBit 生态核对](notes/moonbit-ecosystem.md)（核对日期：2026-10-12，含包版本及来源）。这些差异说明适用范围，不构成独有性或性能优势结论。

## 实际问题与使用场景

Aurum 处理三个可从代码验证的基础计算问题：十进制金额和分摊尾差的守恒、等间隔现金流的时间点与数值合计、按分舍入还款计划的逐期对账。

- **金额分摊**：解析 `100.00 CNY`，按 `[1, 2, 3]` 分配为 `16.67 / 33.33 / 50.00`，核对合计。
- **现金流审阅**：展示 `[-1000, 300, 400, 500]` 在每期 10% 折现率下的逐期现值、NPV 和 IRR；另用抵消压力样例说明十月 NPV 改进。
- **还款测算**：生成 `10000.00 CNY`、每期 1%、12 期的分位计划，对账并比较首期额外还本 `100.00 CNY` 的模型结果。

以上均为**设计场景 / 待验证**，固定输入来自已有回归样例，不能视为真实用户案例或已验证业务收益。每个场景的用户、输入、步骤、输出、价值、功能证据及待补真实材料见[实际问题与完整使用场景](notes/use-cases.md)。运行 `moon run examples/use-cases` 可查看完整流程；这是固定输入的开发者演示。

## 特性

- **精确金额**：按币种最小单位存储；支持严格十进制字符串解析/序列化、显式舍入输入、失败可控运算、整数比例运算和等额/按权重分摊
- **多种舍入策略**：半向上（恰好一半时远离零）、银行家舍入、远离零 / 向零截断
- **货币时间价值**：现值、终值、年金、永续年金
- **资本预算**：补偿求和的 NPV、IRR、回收期、盈利指数
- **贷款摊销**：浮点估算计划，以及按币种最小单位逐期舍入、末期结清的等额本息 / 等额本金计划
- **固定资产折旧**：直线法、双倍余额递减、年数总和、工作量法
- **债券定价**：价格、到期收益率、久期与凸性
- **财务比率**：流动性、偿债、盈利、营运与估值指标
- **多币种**：12 种币种的代码/小数位元数据与调用方提供汇率的换算

## 安装与快速复现

先安装 Git，再使用 [MoonBit 官方安装器](https://www.moonbitlang.com/download/#moonbit-cli-tools)安装本仓库实测的构建 **`0.10.11+6ff76a5f9`**。安装器的版本参数对应 `moonc` 构建号，与下文 `moon` 的版本号不同。VS Code 插件不是运行 CLI 的前提。

Windows PowerShell：

```powershell
$env:MOONBIT_INSTALL_VERSION = "0.10.11+6ff76a5f9"
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

Linux / macOS（官方安装器命令；本次本地验证环境为 Windows，Linux 由 CI 验证）：

```sh
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- '0.10.11+6ff76a5f9'
```

安装后打开新终端，在克隆前运行 `moon version --all`，确认 `moonc v0.10.11+6ff76a5f9`。已有其他工具链时也须核对当前 `PATH` 选择的版本；不要仅凭安装器执行成功判断版本已切换。

```sh
git clone https://github.com/Lyllyl789/aurum.git
cd aurum
git rev-parse HEAD
moon version --all
moon fmt --check
moon check
moon test
moon run bin
moon run examples/use-cases
moon run examples/readme
```

以上命令在仓库根目录执行，适用于 PowerShell 和常见 POSIX shell。`moon.mod` 声明模块名 **`aurum`**、版本 **`0.1.0`**，没有第三方模块依赖；标准库随工具链提供，无须执行 `moon add`、登录 Mooncakes 或配置 API 密钥。GitHub 仓库名不等于 MoonBit 模块名，不能将导入路径写成 `Lyllyl789/aurum/...`。

三个入口均使用固定输入：`bin` 展示八个模块；`examples/use-cases` 串联金额分摊、现金流和还款场景；`examples/readme` 对应下文可复制的完整代码。`bin` 是开发者演示程序，没有交互输入、行情服务或 Web 界面。

快速核对结果：CLI 的抵消现金流 NPV 为 `1`；场景示例的分摊为 `16.67 / 33.33 / 50.00`、合计 `100.00`，基准贷款总利息 `661.86`、额外还本模型利息差 `11.57`、期末余额 `0.00`。普通 NPV 约为 `-21.03681442524436`，IRR 约为 `0.08896339469338166`；浮点显示末位可因后端不同而变化。示例成功退出不等同于真实业务验证，API 边界由下文测试检查。

## 测试与兼容说明

```sh
moon fmt --check
moon check
moon test
moon test lib/money lib/tvm lib/capital lib/amortize lib/integration
moon test lib/capital
```

`moon fmt --check` 只检查格式；需要修改格式时运行 `moon fmt`，然后重新检查。`moon check` 检查类型及包导入；`moon test` 运行全部测试，包含金额精度/溢出、拒绝输入、浮点误差、NPV 抵消回归和跨模块对账。定向核心测试为 68 项，capital 为 10 项，全量为 93 项（累计测试，非十月全部新增）。任一命令非零退出均须处理；这些检查不证明生产适用性或业务口径适合具体用途。

2026-10-12 在 Windows 上实测：`moon 0.1.20260827 (d0aaa07 2026-08-27)`、`moonc v0.10.11+6ff76a5f9 (2026-08-28)`、`moonrun 0.1.20260827`。配置使用 `moon.mod` / `moon.pkg` 文本格式，未测定最低兼容版本；不能识别这些文件的工具链应按上文安装已验证构建。默认 wasm-gc 后端通过上述检查、93 项测试和三个演示，无须额外安装 Node.js 或本地 C 编译器。

另在同一 Windows 工具链和 Node.js v24.19.0 环境实测 JS 后端：

```sh
moon check --target js
moon test --target js
moon run --target js bin
moon run --target js examples/use-cases
moon run --target js examples/readme
```

JS 后端全量 93 项测试通过；运行 JS 需要可从 `PATH` 调用的 Node.js。CI 在 Ubuntu 22.04 安装与上述实测相同的 `0.10.11+6ff76a5f9` 构建，检查格式、类型、测试及三个默认后端演示；远端结果以 [GitHub Actions](https://github.com/Lyllyl789/aurum/actions) 对应提交的状态为准。macOS、native、llvm 和其他工具链版本未在本次本地复现中验证，不宣称全平台兼容。

不要将安装器参数改为 `latest` 后直接假定复现结果相同：2026-10-12 的 `moonc v0.10.15+943464bfa` 格式器要求把现有 `Int` 声明迁移为 `Int32`，使未迁移源码的 `moon fmt --check` 失败。首次 README 提交的 [CI 失败日志](https://github.com/Lyllyl789/aurum/actions/runs/38238057636)记录了这一差异；仓库通过固定已验证构建修复环境漂移。后续工具链升级需重新检查全部命令。

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
├── examples/
│   ├── readme/          # README 完整导入与运行示例
│   └── use-cases/       # 三个固定输入场景
├── notes/               # 设计笔记
└── moon.mod
```

## 使用与包导入

### 仓库内可运行示例

在可执行包的 `moon.pkg` 中声明依赖（与 [examples/readme/moon.pkg](examples/readme/moon.pkg) 相同）：

```moonbit
import {
  "aurum/lib/money",
  "aurum/lib/tvm",
  "aurum/lib/capital",
  "aurum/lib/amortize",
}

pkgtype(kind: "executable")
```

包的默认别名是路径最后一段，例如 `aurum/lib/money` 对应 `@money`。其余四个库包为 `aurum/lib/wear`、`aurum/lib/bond`、`aurum/lib/ratio`、`aurum/lib/currency`；按需要添加导入。根目录没有提供汇总所有 API 的 `aurum` 包。

以下是完整 `main.mbt`，与 [examples/readme/main.mbt](examples/readme/main.mbt) 的执行代码一致。金额构造使用整数最小单位（CNY 为分），利率按每期小数传入；对返回 `Option` 的 API 显式处理 `None`。演示遇到这些失败会中止，实际应用应按自身需求返回错误或提示用户。

```moonbit
///|
fn main {
  let a = @money.Money::of(12345, "CNY")
  let b = @money.Money::of(100, "CNY")
  println("金额合计 CNY = " + a.add(b).to_decimal_string())
  let invoice = match @money.Money::parse("100.00", "CNY") {
    Some(value) => value
    None => abort("invalid invoice")
  }
  let shares = match invoice.allocate_by_weights([1, 2, 3]) {
    Some(value) => value
    None => abort("invalid weights")
  }
  for share in shares {
    println("份额 CNY = " + share.to_decimal_string())
  }
  match @tvm.future_value(10000.0, 0.05, 10) {
    Some(value) => println("终值估算 = " + value.to_string())
    None => abort("invalid TVM input or non-finite result")
  }
  match @capital.net_present_value(0.10, [-1000.0, 300.0, 400.0, 500.0]) {
    Some(value) => println("NPV 估算 = " + value.to_string())
    None => abort("invalid cashflows or non-finite result")
  }
  let rows = match
    @amortize.equal_installment_money_schedule(
      @money.Money::of(1000000, "CNY"),
      0.01,
      12,
      @money.round_half_up(),
    ) {
    Some(value) => value
    None => abort("invalid loan input or overflow")
  }
  let summary = match @amortize.summarize_money_schedule(rows) {
    Some(value) => value
    None => abort("loan reconciliation failed or overflow")
  }
  println("贷款总利息 CNY = " + summary.interest.to_decimal_string())
  println(
    "贷款期末余额 CNY = " + summary.ending_balance.to_decimal_string(),
  )
}
```

在仓库根目录运行 `moon run examples/readme`，预期输出：

```text
金额合计 CNY = 124.45
份额 CNY = 16.67
份额 CNY = 33.33
份额 CNY = 50.00
终值估算 = 16288.946267774423
NPV 估算 = -21.03681442524436
贷款总利息 CNY = 661.86
贷款期末余额 CNY = 0.00
```

### 从另一个本地 MoonBit 模块导入

复现采用公开 Git 源码，不假定 `aurum@0.1.0` 已在 Mooncakes 发布。准备一个新目录 `review-workspace`，将本仓库克隆为其子目录 `aurum`，并创建以下文件布局：

```text
review-workspace/
├── moon.work
├── aurum/                 # git clone 得到的本仓库
└── review-app/
    ├── moon.mod
    └── main/
        ├── moon.pkg
        └── main.mbt
```

`review-workspace/moon.work`：

```moonbit
members = [
  "aurum",
  "review-app",
]
```

`review-app/moon.mod`：

```moonbit
name = "review-app"

version = "0.1.0"

import {
  "aurum@0.1.0",
}
```

将上文 `moon.pkg` 和完整 `main.mbt` 分别保存到 `review-app/main/`。在 `review-workspace` 目录执行：

```sh
moon -C review-app fmt --check
moon -C review-app check
moon -C review-app run main
```

结果应与仓库内示例一致。[MoonBit 本地工作区规则](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html#dependency-management)使 `aurum` 从 `moon.work` 的本地成员解析；`0.1.0` 对照本仓库元数据填写，不是已发布版本的证明。缺少工作区配置会导致依赖无法按这个流程解析；仅复制 `.mbt` 或仅在包文件中写 `import` 不能替代模块依赖声明。

### 货币 API 约定

`Money::of(minor, currency)` 和 `Money::zero(currency)` 只接受当前列出的代码，金额始终是该币种的整数最小单位。当前支持 CNY、USD、EUR、GBP（2 位小数），JPY、KRW、VND（0 位），KWD、BHD、OMR、JOD、TND（3 位）；这不是完整 ISO 4217 数据库。`currency_decimals(code)` 返回受支持币种的小数位数。未知代码或大小写错误会中止，构造函数不返回 `Option`。

需要将外部十进制文本读入金额时，`Money::parse(text, currency)` 接受 ASCII 数字和 `.`，不接受空白、千分位或指数写法；超过币种精度的非零小数位返回 `None`，多出的零不改变金额。`Money::parse_rounded` 显式接受舍入模式。`Money::try_of` 是 `Money::of` 的非中止版本。`scale_ratio(numerator, denominator, mode)` 使用整数最小单位做比例计算，分母须为正，溢出返回 `None`。

`to_decimal_string()` 输出适合持久化和重新解析的固定精度、无千分位文本；`format()` 仍用于带千分位的展示。`try_add` 与 `try_sub` 在币种不一致或运算溢出时返回 `None`；`try_compare` 仅在币种不一致时返回 `None`（比较不涉及数值溢出）；`Money::sum` 在币种混用或累加溢出时返回 `None`；单金额的 `try_scale`、`try_neg` 在结果超出 32 位最小单位范围时返回 `None`。`to_major_double()` 与 `ratio_to()` 是方便估算的浮点桥接，不再保持整数金额的精确性。

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

`@capital.discounted_cash_flow_schedule(rate, cashflows)` 返回 NPV 的逐期现值分解，期号从 0 开始，便于审计每项折现贡献；只需要合计时继续使用不分配明细数组的 `net_present_value`。

| 模块 | 当前实现的返回与校验 |
| --- | --- |
| `amortize` | 浮点 API 要求有限本金、每期利率大于 -1、期数大于 0；返回 `Double?` 或 `Array[Payment]?`。`Money` 计划要求正本金、非负每期利率，利息逐期按指定舍入模式到币种最小单位；可传入可选额外本金，提前结清后的行置零，最后一个非零还款调整为结清余额。`summarize_money_schedule` 校验期号、币种、逐期加总和余额衔接，并汇总本金/利息/还款。 |
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

## 设计、验证与贡献记录

- **设计规范**：[设计笔记](notes/design.md) 详细记录了各模块实现边界与数值精度策略。
- **AI 辅助说明**：[AI 使用范围](notes/ai-review.md) 记录实际 AI 参与范围和当前人工确认状态。
- **开发记录**：[功能变化与验证记录](notes/development-log.md) 按阶段概述项目改动、AI 辅助范围和可复现检查。
- **功能对照与回归验证**：[功能对照与回归验证](notes/comparison-and-acceptance.md) 记录了项目功能范围、成熟工具功能矩阵对照、差异说明和固定可复现回归值。

## 参考来源

Aurum 是开源基础计算库，所用金融公式和数值方法来自通行的公开知识；以下说明方法来源，不构成原创性或性能优势声明：

- 货币时间价值、债券定价、贷款摊销与固定资产折旧的标准公式，属于通行的财务管理 / 金融数学公式。
- 内部收益率（IRR）与到期收益率（YTM）使用二分法求根；IRR 的单次符号变化检查是本库的保守返回契约，具体搜索区间和失败条件见 API 约定。
- 年金公式以 `ln_1p` / `expm1` 替代朴素幂运算，以减少利率接近零时的抵消误差，参考数值计算的通行惯例。

## 许可证

Apache-2.0
