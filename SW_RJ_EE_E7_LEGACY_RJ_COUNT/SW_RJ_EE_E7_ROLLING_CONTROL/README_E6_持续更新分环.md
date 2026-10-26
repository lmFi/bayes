# 历史文档：E6一次重置、完整增长历史、持续更新分环

> 当前E7不再使用增长全历史，请先阅读 `README_先读我.md`。

本版本以 E5 sequential EE 为基线。每条温度链每轮仍然先执行一次原有
RJ/MH 局部更新，然后链 1 到链 T-1 才以 `ee_probability` 的概率补充一次
EE 跳跃。Birth、Death、Change、Move、先验和原绘图没有改动。

## 时间流程

默认参数下：

1. `1001:3000`：第一次能量校准；第 3000 轮生成初始成对边界。
2. `3001:4000`：填充候选；第 4001 轮开始补充 EE。
3. `3001:18000`：使用最近 `ee_adapt_window=4000` 轮能量更新边界。
4. 第 `ee_reset_iteration=18000` 轮末：先生成一套边界，随后只清空候选档案；边界保留。
5. `18001:20000`：建立干净的后重置档案。
6. 第 20000 轮末第一次用 `18001:20000` 的全部能量更新边界。
7. 后续每 `ee_postreset_update_interval=5000` 轮，用 `18001:当前轮` 的全部能量更新边界，直到运行结束。

每次边界改变后，程序只把已保存模型按新边界重新建立索引，不重新正演，
不去重，也不删除拒绝造成的停留重复。新边界从下一轮生效；当前轮的最终
状态只能从以后轮次被抽取。

## 关键区别

- 重置前：最近窗口用于探索，旧高能量会退出校准窗口。
- 重置时：预热候选全部删除，避免污染正式阶段。
- 重置后：所有完成状态永久保留，不再 FIFO 淘汰。
- 重置后边界：使用全部干净历史累计估计，不用固定长度窗口。
- 边界持续变化：这是实验性、递减影响的自适应方案，不等同于固定核 MCMC 的严格有限步收敛证明。

## 运行与检查

```matlab
run_self_tests
result_file = Run_sequential_EE;
inspect_adaptive_ee(result_file)
```

正常长跑结束时应满足：

- `EE.archive_reset_at == cfg.ee_reset_iteration`；
- 每条链 `EE.archive_count == nsample-ee_reset_iteration`；
- `EE.archive_dropped == 0`；
- 后重置 `edge_updates.pilot_start` 始终为 `ee_reset_iteration+1`；
- `Local RJ updates per chain` 等于总迭代数。

如果只想做严格固定边界的最终对照，应另跑一个冻结边界版本；不要把本版
“持续自适应”的样本自动解释成已经获得严格平稳后验。
