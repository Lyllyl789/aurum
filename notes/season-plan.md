# Aurum 功能范围与版本记录

Aurum 是一个用 MoonBit 编写的基础金融计算库。本文记录当前实现范围、九月已有能力和十月维护改动，避免把历史功能误记为本期新增。

## 项目范围

核心能力是最小单位金额运算、周期现金流估算和按最小单位舍入的还款计划。`wear`、`bond`、`ratio`、`currency` 提供边界有限的公式或转换示例，不代表完整会计、债券市场估值、财报分析或外汇服务。金融指标使用 `Double` 估算；项目不处理实时行情、日期日历、收益率曲线、税务或法规校验。

## 九月已有基础

比较基线为九月末提交 [`8e9cd48`](https://github.com/Lyllyl789/aurum/commit/8e9cd48b95d8102589d87131572ae58406263a92)。以下能力在十月开始前已存在：

| 模块 | 已有能力 |
| --- | --- |
| `money` | 整数最小单位金额、十进制解析与格式化、舍入、同币种运算及权重分摊 |
| `tvm` | 现值、终值、年金及名义/有效年利率换算 |
| `capital` | NPV、IRR、回收期、盈利指数及逐期折现明细 |
| `amortize` | 周期还款估算、按最小单位舍入的还款计划、额外还本及摘要对账 |
| `wear`、`bond`、`ratio`、`currency` | 固定资产折旧、简化债券计算、财务比率及有限币种/外部汇率示例 |

这些历史模块和对应测试属于项目既有基础，不计作十月新增功能。

## 十月维护改动

| 改动 | 内容 | 可核对位置 |
| --- | --- | --- |
| NPV 数值稳定性 | 对逐期现值求和加入 Neumaier 补偿；抵消输入 `[1e16, 1, -1e16]`、折现率 `0` 的结果为 `1` | [`9c62fe2`](https://github.com/Lyllyl789/aurum/commit/9c62fe2363512c61d6108738e8c59b0e0ab3ee3b)、`lib/capital/capital.mbt`、`lib/capital/capital_test.mbt` |
| 场景示例 | 串联金额分摊、现金流估算和还款对账；关键固定结果不符时演示失败 | `examples/use-cases/` |
| 可复现步骤 | 增加完整导入示例及仓库内运行方式 | `examples/readme/`、README |
| CI 环境 | 固定已验证的 MoonBit 工具链版本；CI 检查格式、类型、测试、CLI 和示例 | `.github/workflows/ci.yml` |

场景输入是合成的设计示例，不是客户数据、真实贷款或访谈结果。示例结果只验证固定输入下的程序行为，不能证明实际业务价值。

## 验证

当前版本的 GitHub Actions 格式、类型、全量测试、CLI、场景和 README 示例步骤均通过：[检查记录](https://github.com/Lyllyl789/aurum/actions/runs/38250264099)。测试总数包含九月已有测试；十月新增的金融单元回归为 NPV 抵消用例一项，场景示例中的断言不计作单元测试。

NPV 仍以 `Double` 计算。补偿求和能改善部分浮点累加误差，但不提供任意精度，也不保证适用于未经业务复核的资金结算。

## 相关资料

- [三个固定输入场景](use-cases.md)
- [功能范围与回归样例](comparison-and-acceptance.md)
- [AI 辅助说明与人工复核清单](ai-review.md)
- GitHub：[Lyllyl789/aurum](https://github.com/Lyllyl789/aurum)
