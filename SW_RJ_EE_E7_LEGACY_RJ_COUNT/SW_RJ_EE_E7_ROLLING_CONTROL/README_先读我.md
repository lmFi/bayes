# SW_RJ_EE_E7_ROLLING_CONTROL

本版只改变EE边界更新与候选历史管理。Birth、Death、Move、Change、先验、
似然、正演、温度和原有反演绘图保持基线代码不变。

## 两个严格对照组

两组共同设置：

- 每次分环只使用最近4000轮的似然能量；
- 每条链只保留最近8000个完整状态，严格FIFO；
- 第18000轮先更新边界，再删除此前全部候选状态；
- 每轮先完成一次局部RJMCMC，随后以0.10概率追加EE；
- 相邻链对分别建立边界，候选来自相邻高温链同环历史；
- 边界更新后，把当前8000状态重新索引，不重新正演。

唯一实验差异：

- `continuous`：第18000轮以后仍每2000轮更新边界，直到运行结束；
- `frozen`：第18000轮生成最后一套边界，此后边界固定。候选FIFO仍持续更新。

正式后验从第20001轮开始，所以冻结组在后验开始前已有2000个干净候选状态。

## 运行

```matlab
clear functions
run_self_tests
check_true_model_forward(rj_ee_options('five','continuous'))

file_continuous = Run_rolling_EE;
file_frozen = Run_frozen_EE;
```

相同种子自动跑两组：

```matlab
files = Run_rolling_vs_frozen(24,'five');
```

多个独立种子：

```matlab
files = Run_rolling_vs_frozen([24 26 27],'five');
```

也可以手动修改非EE参数后运行：

```matlab
cfg = rj_ee_options('five','continuous');
cfg.seed = 26;
file = Main_rjmcmc_EE(cfg);
```

## 时间表（默认40000轮）

| 轮次 | 操作 |
|---|---|
| 1001:3000 | 首次成对能量校准 |
| 3001:4000 | 填充候选库 |
| 4001起 | EE可用 |
| 4000,6000,...,18000 | 两组均滚动更新边界 |
| 18000 | 两组均清空旧候选；保留刚生成的边界 |
| 18001起 | 候选库只保留每条链最近8000个完整状态 |
| 22000,24000,... | 仅continuous继续更新边界；先凑满4000个重置后能量 |
| 20001起 | 收集后验 |

第40000轮更新得到的边界只用于完整记录更新时间；由于没有第40001轮，它不会影响
本次运行的跳跃。分析有效边界时应查看 `active_from <= nsample` 的epoch。

## 解释边界

`continuous` 是持续自适应工程实验，后验阶段的转移机制仍在改变，不能仅凭高接受率
声称得到严格固定核的后验收敛。`frozen` 才是主要统计基线。比较时至少同时检查独立
种子间的K分布、K_half_TV、ESS、能量分段稳定性、速度剖面和正演拟合。
