# 开发记录

## 2026-09-27 01:00–01:06（Asia/Shanghai）：初审第一阶段，自动化执行

**用户提出的工程目标**：只操作本地 Aurum 仓库，保留既有改动；以源码为准核对申报承诺；修正 API 契约与 AI 辅助透明度说明；先定向测试、再完整验证；验证通过后提交并推送 `origin/main`。本阶段不大范围重写金融算法。人工最终签字由用户本人决定。

**开始状态**：`git status --short --branch` 显示 `## main...origin/main` 且无未提交文件；`git branch --show-current` 为 `main`；`git remote -v` 的 fetch/push 地址均为 `https://github.com/Lyllyl789/aurum.git`；最近提交为 `bb455fa 完善多币种模块并统一 API 风格`（此前依次 `ec2a654`、`0400462`、`fb65898`、`37f25a0`）。没有覆盖已有用户改动。

**核对范围与结论**：自动化读取 README、`notes/design.md`、`bin/main.mbt`、全部 `lib` 中的 `.mbt` 源码与测试，以及 MoonBit 清单。仓库内未发现 Aurum 项目申报书，故不能核对或改写其原件；申报书原文仍待人工提供并复核。发现 README 错写“未提供汇率转换”，设计笔记将所有浮点 API 的 `None` 语义概括过宽；`Money` 采用中止契约；`currency.convert` 使用调用方汇率和 `Double`，原来未拦截舍入结果越过 `Int` 范围。

**本次实际改动，全部由自动化草拟/执行，待人工复核**：

- `lib/currency/currency.mbt`：在 `Double` 换算后检查 half-up 舍入是否仍落在 32 位 `Int` 范围内，并处理可表示的负边界；`currency_test.mbt` 新增非有限汇率、溢出及负边界断言。
- `README.md`、`notes/design.md`：按代码修正模块清单、`Money` 中止契约、各 `Option` 的实际含义、精度边界、12 币种范围和外部汇率输入。删去未经本阶段核实的作者/独立编写断言。
- `notes/ai-review.md`：写明人工最终决定权、允许的 AI 辅助范围、本次自动化实际工作和待人工复核清单；无人工签字或用户试用声明。
- 为使仓库级 `moon fmt --check` 通过，运行 `moon fmt`；因此 `bin`、多个 `lib` 的源码/测试及清单出现机械格式差异。未借此改写金融算法。

**命令与真实结果**：

| 命令 | 结果 |
| --- | --- |
| `rg --files`、`Get-Content`、`rg -n`（仓库文件清单、文档、全部 `lib` 源码/测试） | 完成上述逐文件核对；仓库仅有 README 和设计笔记两份原有 Markdown，未找到 Aurum 申报书。 |
| `moon test --help`、`moon fmt --help` | 成功；确认 `moon test` 支持路径参数，`moon fmt` 支持 `--check`。 |
| `moon test lib/money lib/currency`（修改前） | 退出码 0；28/28 通过。 |
| `moon test lib/currency lib/money`（加入初次边界断言后） | 退出码 0；28/28 通过。 |
| `moon fmt --check`（首次仓库级） | 退出码 1；原有多个 `.mbt`/清单与格式器输出不同，包括尚未修改的模块。 |
| `moon fmt` | 退出码 0；报告 27 tasks，产生上述机械格式差异。 |
| `moon fmt lib/currency` | 退出码 0；报告 3 tasks。 |
| `moon test lib/currency lib/money`（最终定向） | 退出码 0；29/29 通过。 |
| `moon fmt --check`（格式化后） | 退出码 0；报告 3 tasks，now up to date。 |
| `moon check` | 退出码 0；报告 18 tasks，now up to date。 |
| `moon test` | 退出码 0；62/62 通过。 |
| `moon run bin` | 退出码 0；演示打印 TVM、NPV/IRR、摊销、折旧、债券、比率及 `100.00` CNY 按外部汇率 `0.14` 换成 `14.00` USD。 |
| `git diff --check` | 退出码 0；仅有 Git 的 LF/CRLF 换行符提示。 |

上述是自动化实际执行结果，不代表人工复核、用户试用或初审机构验收。

## 2026-09-27 07:36–07:41（Asia/Shanghai）：初审第二阶段，自动化执行

**用户提出的工程目标**：承接第一阶段真实提交，只处理有证据的功能边界与测试质量；先针对性测试再完整验证；补跨模块可核对场景、CLI 边界和 CI；如实记录 AI 辅助与人工决策边界，验证通过后提交并推送 `origin/main`。本阶段所有实际代码、测试、文档及命令均由自动化草拟/执行，**待人工复核**，不声称人工验收、用户试用或最终签字。

**开始状态与远端**：`git branch --show-current` 为 `main`；`git status --short` 为空；`origin` fetch/push 均为 `https://github.com/Lyllyl789/aurum.git`。阅读前一阶段开发记录、README、设计与 AI 复核说明，确认上一阶段本地验证已完成。本次未覆盖已有用户改动。

**逐模块边界审查与证据**：

| 模块 | 证据及本阶段处理 |
| --- | --- |
| `money` | 原 `round_div` 以 `Int` 计算 `abs_r * 2`；新增 `1073741824 / 2147483647` 回归先得到 0 而预期半向上为 1。改用 `Int64` 比较，保持原 API 和负数模式行为。`add/sub/neg/scale` 溢出、币种不匹配中止已有测试；明确 `round_down/up` 是向零/远离零而非数学 floor/ceil，不作不兼容改写。 |
| `tvm` / `capital` | 现有测试覆盖 NaN/Infinity、结果溢出、`rate <= -1`、负期数、空现金流、无根/多根 IRR、未回收 payback、NPV 数值与 IRR 残差；源码相应守卫存在。本次未改动算法。IRR 多次符号变化保守返回 `None`，搜索区间边界仍按 README 契约。 |
| `amortize` | 原等额本金计划仅检查余额，`principal=1e308, rate=10, periods=2` 可返回含 Infinity 利息的计划；定向测试先失败。现检查计划字段有限。原总利息用 `periods + 1` 的 `Int` 加法，最大期数产生溢出；测试先失败，改为转 `Double` 后相加。利率、负期数原有测试继续通过。 |
| `wear` | 原年数总和用 `Int` 计算 `life * (life + 1)`，`life=100000` 时溢出；定向测试先失败，改为浮点计算分母。残值高于成本、当期工作量大于总量会产生负/超额折旧；新增当前行为回归与文档，业务合法性由人工决定，不擅自规定财务标准。 |
| `bond` | 原测试仅有部分非法参数；新增 `rate=-1`、Infinity、零市场价无法求 YTM、零价无法计算久期/凸性的 `None` 回归；未添加缺乏项目依据的票息/面值符号规则。 |
| `ratio` | 原仅拒绝零分母与非有限结果，`1000 / Infinity` 会返回 `Some(0)`；定向测试先失败。现拒绝非有限操作数，并覆盖 NaN、Infinity 与除零。 |
| `currency` | 第一阶段已有 NaN/Infinity、非正汇率、未知目标币种、越过 `Int` 范围及负边界测试；本阶段跨模块场景重验正常换汇和零汇率失败。 |

**跨模块场景**：新增 `lib/integration` 测试：100.00 CNY 按调用方提供的 0.14 USD/CNY 换为 14.00 USD，再按单期利率 5% 计算一期等额本息，核对本金 14.00、利息 0.70、余额 0、还款约 14.70；按美分舍入得到 1470 最小单位。分别断言零汇率和 `rate=-1` 返回 `None`。CLI 使用同一算例，输出舍入后的 14.70 USD，并展示零汇率与未回收 payback 的 `None` 语义。汇率是示例输入，不是实时行情；浮点还款数为估算。

**CI**：原 `.github/workflows/ci.yml` 只有 `moon check` 和 `moon test`；加入 `moon fmt --check` 与 `moon run bin`，沿用现有工具链安装和触发条件。仅在本地执行了对应命令，远端 CI 是否运行成功须等推送后核对。

**命令与真实结果**：`moon test lib/money`、`lib/ratio`、`lib/amortize`、`lib/wear` 在测试先行时各有 1 个新回归失败；最小修复后 `moon test lib/money lib/ratio lib/amortize lib/wear` 为 42/42。新增最大期数回归后 `moon test lib/amortize lib/wear lib/bond` 为 19/20，修复后为 20/20。跨模块测试 `moon test lib/integration` 为 1/1。首次将该测试放在 `bin` 的 blackbox 文件时 MoonBit 发出未来兼容性提示，已移入独立包；随后清除未使用包/隐式 core 包警告。运行 `moon fmt` 后，`moon fmt --check`、`moon check`、`moon test`、`moon run bin`、`git diff --check` 均退出码 0；全量 `moon test` 为 70/70。CLI 起初直接显示浮点 `14.699999999999989`，后改为明确按美分舍入显示 `14.70`，并复跑 `moon test lib/integration`（1/1）与 `moon run bin`（退出码 0）。`git diff --check` 仅有 Windows LF/CRLF 提示，无空白错误。

上述本地验证与代码仍待人工复核。

**提交前最终完整验证**：在 CLI 按美分舍入与文档更新后依序运行 `moon fmt`、`moon fmt --check`、`moon check`、`moon test`、`moon run bin`、`git diff --check`，六项均退出码 0。`moon test` 为 70/70；演示显示约 14.70 USD、零汇率 `None`、未回收回收期 `None`。差异检查仅有 LF/CRLF 提示。此为本地执行结果，尚非远端 CI 结果。
