# MoonBit 生态定位与边界核对

核对日期：**2026-10-12（Asia/Shanghai）**。本页说明相邻能力、数值模型差异和 Aurum 的适用范围。

## 核对方法与证据范围

- 从 [Mooncakes](https://mooncakes.io/) 的模块目录和搜索接口查找 `finance`、`financial`、`money`、`decimal`、`rational`、`npv`、`loan`、`bond`、`accounting`、`aurum`，再阅读相关模块的已发布 README、API 类型和函数签名。可复查入口：[模块目录](https://mooncakes.io/api-new/v0/modules)、[finance 搜索](https://mooncakes.io/api-new/v0/search?kw=finance&limit=20)、[decimal 搜索](https://mooncakes.io/api-new/v0/search?kw=decimal&limit=20)、[loan 搜索](https://mooncakes.io/api-new/v0/search?kw=loan&limit=20)。搜索每项最多 20 个结果，目录元数据和搜索索引也可能不完整；关键词无命中不能证明某类能力不存在。
- 下表选取与金额、现金流和贷款直接相关的包及邻近的报表、模拟、导入能力，**不是全生态清单**。包版本固定在链接中；官方 core 另记录本次读取的发布版本。Mooncakes 页面背后的发布数据可从 `https://assets.mooncakes.io/assets/<模块>@<版本>/resource.json`（README）和 `<包路径>/package_data.json`（API）复查。
- 其他项目的能力描述来自其发布文档/API，未安装或运行这些项目，未复跑其测试、性能基准或形式化证明。文档描述不等同于本次独立验证的业务正确性、成熟度或兼容性。
- Aurum 一侧以整理本页时的 [cae9033](https://github.com/Lyllyl789/aurum/commit/cae90336dad088bd5424f9db5ea62caa40ebaf07) 源码、已有测试和固定演示为依据；本次不新增金融算法，也不将既有能力计作十月新增。

## 相邻能力与具体差异

| 已核对包 / 版本及来源 | 文档或 API 可确认的相邻能力 | Aurum 的用途与边界 |
| --- | --- | --- |
| [moonbitlang/x/decimal · 0.5.5](https://mooncakes.io/docs/moonbitlang/x@0.5.5/decimal) | `Decimal` 使用 `BigInt` 系数和 `Int` scale；有字符串解析、十进制运算和舍入，文档列出默认 `max_scale = 28`。 | Aurum `Money` 使用 32 位整数最小单位，按受支持币种确定小数位，提供同币种校验和守恒分摊。它不是任意精度 Decimal；其 TVM/NPV/IRR 仍用 `Double`。避免二进制金额表示误差是两者的相邻能力，不能作为 Aurum 独有性依据。 |
| [DzmingLi/decimal · 0.2.2](https://mooncakes.io/docs/DzmingLi/decimal@0.2.2) | 已发布文档/API 提供 `Decimal`、显式 `Context`（精度、舍入、指数范围）、`Flags` 和 `quantize`；支持十进制金额舍入场景。该版本标为已迁移，详见下文。 | Aurum 以固定最小单位、四种金额舍入策略和领域流程为重点；不提供通用 Decimal 上下文或状态旗标，也不能把财务指标概括为十进制精确计算。 |
| [Luna-Flow/floating · 0.8.0](https://mooncakes.io/docs/Luna-Flow/floating@0.8.0) | README 列出任意精度二进制/十进制、显式精度/舍入/状态与区间算术；[decimal_checked API](https://mooncakes.io/docs/Luna-Flow/floating@0.8.0/decimal_checked) 提供带检查状态的计算封装。 | Aurum 面向币种金额和周期财务公式，不提供可调精度数值系统或区间误差包络。需要这些数值语义时应单独评估相应工具，本次未验证与 Aurum 的集成。 |
| [moonbitlang/x/rational · 0.5.5](https://mooncakes.io/docs/moonbitlang/x@0.5.5/rational)、[core/bigint](https://mooncakes.io/docs/moonbitlang/core/bigint)（本次发布版本 `0.1.20260920+7d59c7ec9`） | `Rational[T]` 表达分子/分母；`new` 返回可失败结果，`div_checked` 可抛出错误；`BigInt` 提供大整数算术。 | Aurum 的整数比例计算会按业务选择舍入回最小单位，不保存通用有理数；金额范围也没有扩展到 `BigInt`。通用数值原语与金额流程有交集，但层次不同。 |
| [lwmvr/moonbit-fixedincome · 0.2.1](https://mooncakes.io/docs/lwmvr/moonbit-fixedincome@0.2.1)；[cashflow API](https://mooncakes.io/docs/lwmvr/moonbit-fixedincome@0.2.1/src/cashflow) | README 覆盖日期/日历、日计数、票息日程、折现曲线、债券风险指标及两类贷款/提前还本。`CashFlow.amount` 与 `LoanPayment` 金额字段为 `Double`；贷款接口接收 `SchedulePeriod` 数组和年利率。 | 两者确实重叠于折现、简化债券、贷款和提前还本。Aurum 的贷款输入为本金、**每期**利率、期数；`Money` 计划逐期舍入到最小单位并在末期结清。Aurum 不建模日期/日计数/曲线；不能只凭“无行情依赖”“可审阅”区分两者，该项目也描述了这些特性。 |
| [bobzhang/prove/loan_amortize · 0.0.3](https://mooncakes.io/docs/bobzhang/prove@0.0.3/loan_amortize) | `amortize(init_bal : Int, rate : Int, pmt : Int, n : Int) -> Int`；文档说明按基点利率做整数计算，并描述逐步守恒证明。 | 整数贷款与守恒检查已有相邻实现。Aurum 接收 `Double` 每期利率及舍入模式，输出逐期 `MoneyPayment` 数组、支持额外还本和摘要对账；本项目只通过自身测试验证这些行为，不宣称已完成形式化证明，也不对上游证明作独立评估。 |
| [mhlagent/moonbit-accounting · 0.3.0](https://mooncakes.io/docs/mhlagent/moonbit-accounting@0.3.0) | README 使用整数最小单位；`Entry` 接收科目、期间、借/贷金额，`generate` 接收分录与科目映射并产生报表；文档另列出日记账校验、试算平衡和报表导出。 | 整数金额和财务比率有交集。Aurum 接收金额、利率、现金流和期数用于计算，不建立科目、分录、账簿或报表。`wear` 与 `ratio` 的公式不使 Aurum 成为会计系统。 |
| [jdjjttr/montecarlo · 0.1.0](https://mooncakes.io/docs/jdjjttr/montecarlo@0.1.0) | README 覆盖可指定种子的模拟、随机过程、衍生品定价、风险与组合分析及结果导出。 | Aurum 的核心流程是确定输入的等间隔现金流和贷款公式，不模拟价格路径，不提供期权、VaR 或组合风险引擎。固定演示可复现不是其独有能力；本次没有两者之间的速度/精度比较。 |
| [mengshi-12/moon-ofx-importer · 0.3.0](https://mooncakes.io/docs/mengshi-12/moon-ofx-importer@0.3.0) | README/API 覆盖离线 OFX 解析、诊断、余额对账；`amount_to_minor_units` 将十进制文本转为 `Int64` 并检查溢出。 | 精确文本金额、最小单位和对账已有相邻能力。Aurum 的解析结果为带币种的 32 位 `Money`，用于分摊和还款计算；不导入银行流水或解析 OFX。导入结果若要交给 Aurum，需另行校验币种、精度及 `Int` 范围，本次未实现适配器。 |

### 迁移信息的核验限制

`DzmingLi/decimal@0.2.2` 的发布 README 指向 [moonbit-community/decimal](https://github.com/moonbit-community/decimal)。本次确认该公开仓库存在，并读取 [ddae991 的模块元数据](https://github.com/moonbit-community/decimal/blob/ddae99174515bc131ab4ef05664c0cd790722ed8/moon.mod)，其版本字段为 `0.1.0`。但本次请求 [Mooncakes manifest](https://mooncakes.io/api-new/v0/manifest/moonbit-community/decimal) 返回 HTTP 404，因此不把仓库版本当作已确认的 Mooncakes 发布版本，不报告安装成功或跨版本兼容。上表的详细 API 结论限定在实际读到的 `DzmingLi/decimal@0.2.2`，不能推导其后继版本完全相同。

## 如何解释 Aurum 的用途

Aurum 的定位是：**供 MoonBit 教学与测算原型使用的小型基础计算库，将有限范围的币种金额、等间隔现金流估算和按最小单位舍入的还款计划放在同一套可检查流程中。**

- 输入 `100.00 CNY` 和权重 `[1, 2, 3]`，需要得到 `16.67 / 33.33 / 50.00` 并核对合计时，Aurum 提供金额解析、分摊及同币种求和流程。若任务是通用高精度十进制运算，应另行评估 Decimal 类工具。
- 输入 `[-1000, 300, 400, 500]` 和每期 10% 折现率，需要说明 `t=0`、逐期现值、NPV 和保守的 IRR 失败条件时，Aurum 提供周期估算流程。若需要带日期的票息、日计数与曲线，应另行评估固定收益工具。
- 输入 `10000.00 CNY`、每期 1%、12 期和舍入模式，需要核对每期还款分解、额外还本及期末余额时，Aurum 提供 `Money` 计划和摘要。若需要从会计分录生成报表、从银行文件导入流水或模拟市场风险，应分别评估相应生态包。

这些是可复现的**设计场景 / 待验证**，不是实际用户或业务收益证据；完整流程见[使用场景](use-cases.md)。上述用途不构成“唯一”“首个”“没有类似项目”或优于其他包的结论，也没有证明其他包无法组合实现同类流程。当前不承诺包间自动互操作、生产资金结算或完整金融/会计平台能力。

## Aurum 侧的针对性核验

依据 [`money`](../lib/money/money.mbt)、[`capital`](../lib/capital/capital.mbt)、[`amortize`](../lib/amortize/amortize.mbt) 与[集成测试](../lib/integration/integration.mbt)，复查：32 位金额边界、严格解析/显式舍入、分摊守恒、NPV 首项与抵消样例、无效输入、逐期贷款分解及末期归零。执行结果在[开发记录](development-log.md)的 2026-10-12 生态核对条目中记录；外部包仍仅为文档/API 核对。
