# E4近期历史版验证状态

E4.1已将`edge_updates`初始化为与每个epoch记录字段完全一致的空结构体，避免
MATLAB把无字段`struct([])`与有字段记录视为不同结构体。

E4.2将完整状态转移测试使用的逆温度从无效`[1 1]`改为`[1 0.5]`；测试把当前
能量放到非空供体环内的最大历史能量，从而在合法接受率下确定性接受候选。

## 本交付环境已完成

- 核对新增配置字段能够从 `rj_ee_options` 传入 `Main_rjmcmc_EE` 和 `ee_dim_configure`。
- 核对循环FIFO使用稳定槽位；覆盖旧槽位时同步删除其环索引，再加入新环。
- 核对每次更新边界后只对有效FIFO条目重新归环，不重新正演。
- 核对最终冻结轮先记录旧档案占用，再清空档案，从下一轮重新填充。
- 核对原始 `Birth.m`、`Death.m`、`Move.m`、`Change.m`、`RJ_C_mian.m`、
  `logprior_model_state.m`、`ee_dim_logaccept.m` 的SHA256仍与
  `UNCHANGED_CORE_SHA256.json` 一致。

## 当前环境无法完成

当前环境没有MATLAB或Octave，因此没有声称 `run_self_tests` 已执行通过，也没有运行
disba反演。原包中的 `docs/VALIDATION.md` 是较早基线的记录，不代表本次E4改动已经在
MATLAB中验证。

请在本机MATLAB先执行：

```matlab
clear functions
run_self_tests
check_true_model_forward
```

预期新增测试行包含：

```text
PASS: recent FIFO, freeze reset, reindexing, dwell duplicates and past-only draws.
```

随后再运行 `Run_adaptive_EE`。这仍只是程序合同检查，不证明后验收敛或反演改善。
