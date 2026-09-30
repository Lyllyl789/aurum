# 开发记录

## 2026-09-27 01:00–01:06（Asia/Shanghai）：初审第一阶段，工程规范与边界核验

**工程目标**：以源码为准核对申报承诺；规范 API 契约与 AI 辅助透明度说明；先定向测试、再完整验证；验证通过后提交并推送 `origin/main`。本阶段不改动核心金融算法。

**开始状态**：`git status --short --branch` 显示 `## main...origin/main` 且无未提交文件；`git branch --show-current` 为 `main`；`git remote -v` 的 fetch/push 地址均为 `https://github.com/Lyllyl789/aurum.git`；最近提交为 `bb455fa 完善多币种模块并统一 API 风格`。

**核对范围与结论**：逐一审查 README、`notes/design.md`、`bin/main.mbt`、全部 `lib` 中的 `.mbt` 源码与测试，以及 MoonBit 清单。修正 README 中关于汇率转换的描述错误，明确 `Money` 采用前置守卫中止契约，`Double` 浮点 API 采用统一返回 `None` 的安全容错契约；在 `currency.convert` 中增加检查 half-up 舍入是否越过 32 位 `Int` 范围并处理负边界。

**本次实际改动**：

- `lib/currency/currency.mbt`：在 `Double` 换算后检查 half-up 舍入是否仍落在 32 位 `Int` 范围内，并处理可表示的负边界；`currency_test.mbt` 新增非有限汇率、溢出及负边界断言。
- `README.md`、`notes/design.md`：按代码修正模块清单、`Money` 中止契约、各 `Option` 的实际含义、精度边界、12 币种范围和外部汇率输入。
- `notes/ai-review.md`：建立透明的规范文档，明确人工最终决定权、AI 辅助范围与人工复核清单。
- 运行 `moon fmt` 统一代码格式，通过 `moon fmt --check`。

**命令与真实结果**：

| 命令 | 结果 |
| --- | --- |
| `moon test lib/money lib/currency`（修改前） | 退出码 0；28/28 通过。 |
| `moon test lib/currency lib/money`（加入初次边界断言后） | 退出码 0；28/28 通过。 |
| `moon fmt` | 退出码 0；格式化源码。 |
| `moon test lib/currency lib/money`（最终定向） | 退出码 0；29/29 通过。 |
| `moon fmt --check` | 退出码 0；now up to date。 |
| `moon check` | 退出码 0；now up to date。 |
| `moon test` | 退出码 0；62/62 通过。 |
| `moon run bin` | 退出码 0；演示打印各模块结果及 100.00 CNY 换算为 14.00 USD。 |
| `git diff --check` | 退出码 0；无空白错误。 |

## 2026-09-27 07:36–07:41（Asia/Shanghai）：初审第二阶段，极端边界修复与跨模块验证

**工程目标**：处理数值计算中的极端边界情况，增强测试覆盖；补充跨模块综合调用场景、CLI 边界防御和 CI 工作流完善；验证通过后推送到 `origin/main`。

**开始状态**：本地工作区干净，开始针对数值边界进行逐模块防御强化。

**逐模块边界审查与处理**：

| 模块 | 审查证据与处理 |
| --- | --- |
| `money` | 原 `round_div` 以 `Int` 计算 `abs_r * 2`；新增 `1073741824 / 2147483647` 回归测试，改用 `Int64` 比较，保持原 API 和负数模式行为。明确 `round_down/up` 是向零/远离零。 |
| `tvm` / `capital` | 完善 NaN/Infinity、结果溢出、`rate <= -1`、负期数、空现金流、无根/多根 IRR、未回收 payback、NPV 数值与 IRR 残差等守卫与测试。 |
| `amortize` | 等额本金计划增加检查计划字段有限性；总利息避免 `Int` 溢出改为浮点计算。 |
| `wear` | 年数总和法避免大 `life` 时的整数溢出，改为浮点计算分母；完善残值高于成本等业务边界回归。 |
| `bond` | 新增 `rate=-1`、Infinity、零市场价无法求 YTM、零价无法计算久期/凸性的 `None` 回归。 |
| `ratio` | 拒绝非有限操作数（如 `1000 / Infinity`），覆盖 NaN、Infinity 与除零。 |
| `currency` | 校验 NaN/Infinity、非正汇率、未知目标币种及越界。 |

**跨模块场景**：新增 `lib/integration` 测试：100.00 CNY 按调用方提供的 0.14 USD/CNY 换为 14.00 USD，再按单期利率 5% 计算一期等额本息，核对本金 14.00、利息 0.70、余额 0、还款约 14.70；按美分舍入得到 1470 最小单位。断言零汇率和 `rate=-1` 返回 `None`。CLI 输出舍入后的 14.70 USD，并展示零汇率与未回收 payback 的 `None` 语义。

**CI**：完善 `.github/workflows/ci.yml`，全量集成 `moon check`、`moon test`、`moon fmt --check` 与 `moon run bin`。

**命令与真实结果**：
- `moon test lib/money lib/ratio lib/amortize lib/wear lib/bond` 42/42 通过；
- 跨模块测试 `moon test lib/integration` 1/1 通过；
- 全量单元测试 `moon test` 达到 70/70 全量通过；
- `moon run bin` 正常执行，无任何异常。

## 2026-09-30：根据初审驳回意见补充对标与验收

**评审意见**：项目跨度偏大，建议参考成熟语言库或选择对标工具，并补充功能对比与验收说明。

**本轮 AI 辅助工作**：将 README 项目定位调整为 MoonBit 基础金融计算库，区分核心验收能力与有限公式示例；新增 `notes/comparison-and-acceptance.md`，依据 NumPy Financial、Python `decimal` 和 QuantLib 的公开文档整理功能矩阵、差异、非目标和固定验收样例；新增一条集成验收测试；在本清单中标明本轮新增内容仍需项目负责人核对。申报书对应增加范围/对标/验收说明，避免只在仓库回应评审意见。

**验证结果**：`moon fmt --check`、`moon check`、`moon test`（71/71）、`moon run bin`、`git diff --check` 均退出码 0。新增验收用例首次编译时发现 integration 包未导入 `tvm`、`capital` 和 `double`；补充 `moon.pkg` 导入后全量检查通过。

**当时推送状态**：本条记录最初写入时尚未推送，且当前执行环境无法读取项目负责人的 `Lyllyl789` CLI 凭据；没有使用其他账号代推。

**2026-09-30 推送确认**：项目负责人从其已登录 `Lyllyl789` 的命令行执行 `git push origin main`，终端显示 `ff9fd90..b478568 main -> main`。随后只读查询 `git ls-remote origin refs/heads/main` 返回 `b4785684d07312ba1c588115e155a02fdfbd1d25`，与本地 `HEAD` 一致；该提交已同步到 `origin/main`。

## 2026-09-30：围绕核心流程增加可复用能力

**目标与范围**：在不增加金融领域模块的前提下，深化 `money`、`tvm`、`capital` 和 `amortize` 的可应用性。新增功能由 AI 辅助实现，项目负责人尚未完成人工复核；本记录不表示组委会初审通过。

**实现内容**：

- `money`：增加严格十进制解析、指定舍入模式的解析、可往返的无分组十进制序列化；增加 `try_*` 算术、绝对值、同币种比较、精确求和、整数比例运算；增加等额与最大余数权重分摊，明确负金额与余数并列的确定性规则。
- `tvm`：增加名义/有效年利率双向换算，使用 `ln_1p` / `expm1` 改善接近零的稳定性；`amortize` 等额本息估算公式也改用稳定的 `expm1` 形式。
- `capital`：增加逐期折现现金流明细，输出可与 NPV 汇总核对的审计分解；保留仅求总 NPV 时的低内存路径。
- `amortize`：增加按货币最小单位计息/舍入的等额本息和等额本金计划、可选额外还本、期末精确结清和计划摘要对账。
- 更新 README、设计/对标/验收说明、演示程序与本清单；旧版人工复核记录与当前待复核状态分开表述。

**验证**：`moon fmt --check`、`moon check`、`moon test`（92/92）、`moon run bin` 和 `git diff --check` 均通过。源代码行数按 `lib/**/*.mbt` 与 `bin/**/*.mbt` 统计，排除测试文件、空行和注释行：2,006 行；该数字是工程规模描述，不是质量或初审指标。

**推送状态**：本轮更改仍在本地工作区，基于已推送的 `b478568`，尚未提交或推送。提交前应由项目负责人复核本轮 API/金融口径并确认是否接受。
