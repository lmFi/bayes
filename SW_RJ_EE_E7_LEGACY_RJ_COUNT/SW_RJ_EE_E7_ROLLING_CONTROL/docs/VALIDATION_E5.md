# E5交付验证说明

## 修改范围

- `Main_rjmcmc_EE.m`：局部RJ固定每链每轮一次，随后追加可选EE。
- `core/ee_jump.m`：第六输出改为 `ee_selected`，不再指示是否运行RJ。
- `core/ee_initialize.m`：记录E5更新模式及三个阶段的能量/npt。
- 诊断表、图和自测试同步更新。

以下文件必须与E4基线的SHA256完全一致：`Birth.m`、`Death.m`、`Move.m`、
`Change.m`、`RJ_C_mian.m`、`logprior_model_state.m`、`ee_dim_logaccept.m`、
原速度/频散绘图函数。

## MATLAB本机验证顺序

```matlab
clear functions
run_self_tests
check_true_model_forward(rj_ee_options('five'))
file = Run_sequential_EE;
```

关键新增测试输出：

```text
PASS: mandatory local RJ is preserved before supplemental EE attempts.
```

正式运行结束后，四条链的 `EE.local_updates` 必须都等于40000。前三条链的
`EE.jump_triggered` 是额外EE尝试数，不与局部计数相加做“每轮分支守恒”。

本交付环境若无MATLAB/Octave，只能完成静态检查和源码哈希验证；不能把这些检查表述
为真实disba反演已经收敛。

可重复执行静态审计：

```bash
python tests/e5_static_audit.py
python tests/reference_audit.py
```

审计输出保存在 `docs/E5_STATIC_AUDIT.json` 和 `docs/PYTHON_VALIDATION_E5.json`。
