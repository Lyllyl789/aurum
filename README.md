# Aurum

> 精密的金融计算，如金般可靠。

Aurum 是一个用 [MoonBit](https://www.moonbitlang.com) 编写的金融数学与财务管理计算库，
覆盖货币金额、货币时间价值（TVM）、资本预算、摊销、折旧、债券定价与财务比率等核心场景。

## 为什么是 Aurum

金融计算最怕浮点误差——`0.1 + 0.2` 在二进制浮点里并不等于 `0.3`。
Aurum 以最小货币单位（分）为存储基础，全程整数运算，从根源上规避精度丢失。

## 特性

- **精确金额**：以"分"存储，四则运算不丢精度
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
// 以最小货币单位（分）构造金额
let a = Money::of(12345, "CNY")  // 123.45 元
let b = Money::of(100, "CNY")    // 1.00 元

let total = a.add(b)             // 12445 分
println(total.format())          // 124.45

// 货币时间价值：10000 元按 5% 复利 10 年
let fv = future_value(10000.0, 0.05, 10)

// 资本预算：净现值与内部收益率
let cf = [-1000.0, 300.0, 400.0, 500.0]
let npv = net_present_value(0.10, cf)
let irr = internal_rate_of_return(cf)
```

## 进度

- [x] `money` 精确金额与舍入
- [x] `tvm` 货币时间价值
- [x] `capital` 资本预算（NPV / IRR）
- [ ] `amortize` 贷款摊销
- [ ] `wear` 折旧
- [ ] `bond` 债券定价
- [ ] `ratio` 财务比率
- [ ] `currency` 多币种

## 许可证

Apache-2.0
