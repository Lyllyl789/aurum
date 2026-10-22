# Aurum 功能范围与维护记录

Aurum 是一个用 MoonBit 编写的基础金融计算库。本文记录项目当前范围、技术演进和可复现验证结果。

## 项目范围

核心能力是最小单位金额运算、周期现金流估算和按最小单位舍入的还款计划。`wear`、`bond`、`ratio`、`currency` 提供边界有限的公式或转换示例，不代表完整会计、债券市场估值、财报分析或外汇服务。金融指标使用 `Double` 估算；项目不处理实时行情、日期日历、收益率曲线、税务或法规校验。

## 初始模块范围

比较基线为 2026-09-30 的提交 [`8e9cd48`](https://github.com/Lyllyl789/aurum/commit/8e9cd48b95d8102589d87131572ae58406263a92)。以下模块构成仓库的初始功能范围：

| 模块 | 已有能力 |
| --- | --- |
| `money` | 整数最小单位金额、十进制解析与格式化、舍入、同币种运算及权重分摊 |
| `tvm` | 现值、终值、年金及名义/有效年利率换算 |
| `capital` | NPV、IRR、回收期、盈利指数及逐期折现明细 |
| `amortize` | 周期还款估算、按最小单位舍入的还款计划、额外还本及摘要对账 |
| `wear`、`bond`、`ratio`、`currency` | 固定资产折旧、简化债券计算、财务比率及有限币种/外部汇率示例 |

各模块以明确输入边界、可检查结果和对应测试为目标，不承诺完整会计或市场估值能力。

## 后续维护改动

| 改动 | 内容 | 可核对位置 |
| --- | --- | --- |
| NPV 数值稳定性 | 对逐期现值求和加入 Neumaier 补偿；抵消输入 `[1e16, 1, -1e16]`、折现率 `0` 的结果为 `1` | [`d621e51`](https://github.com/Lyllyl789/aurum/commit/d621e518f3c83ecb672b2905b76dac55f768bb8c)、`lib/capital/capital.mbt`、`lib/capital/capital_test.mbt` |
| 场景示例 | 串联金额分摊、现金流估算和还款对账；关键固定结果不符时演示失败 | `examples/use-cases/` |
| 可复现步骤 | 增加完整导入示例及仓库内运行方式 | `examples/readme/`、README |
| CI 环境 | 固定已验证的 MoonBit 工具链版本；CI 检查格式、类型、测试、CLI 和示例 | `.github/workflows/ci.yml` |

场景输入是合成的设计示例，不是客户数据、真实贷款或访谈结果。示例结果只验证固定输入下的程序行为，不能证明实际业务价值。

## 验证

历史版本的 GitHub Actions 格式、类型、全量测试、CLI、场景和 README 示例步骤均通过：[检查记录](https://github.com/Lyllyl789/aurum/actions/runs/38268553500)。当前维护分支另以新工具链执行格式、类型、构建、测试和示例验证；结果以对应提交的 GitHub Actions 状态为准。

NPV 仍以 `Double` 计算。补偿求和能改善部分浮点累加误差，但不提供任意精度，也不保证适用于未经业务复核的资金结算。

## 相关资料

- [三个固定输入场景](use-cases.md)
- [功能对照与回归样例](comparison-and-regression.md)
- [AI 辅助与人工决策说明](ai-assistance.md)
- GitHub：[Lyllyl789/aurum](https://github.com/Lyllyl789/aurum)
