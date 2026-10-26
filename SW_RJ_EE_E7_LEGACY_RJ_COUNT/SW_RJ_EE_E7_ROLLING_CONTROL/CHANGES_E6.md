# E6 修改清单

相对 `SW_RJ_EE_E5_SEQUENTIAL`，本版只修改 EE 调度、历史管理、配置、诊断和测试。

## 算法文件

- `core/ee_adaptive_update.m`
  - 重置前使用最近窗口校准；
  - 重置时保留新边界并清空旧候选；
  - 重置后使用全部干净能量累计校准；
  - 更新持续到运行结束；
  - 每次更新后重新索引全部候选。
- `core/ee_dim_configure.m`
  - 验证 E6 日程；
  - 自动分配 `nsample-reset_iteration` 个后重置槽位；
  - 预声明完整 `edge_updates` 结构，避免不同结构体赋值错误。
- `core/ee_adaptive_archive_append.m`
  - 禁止重置后淘汰任何状态。
- `core/ee_adaptive_archive_reset.m`
  - 只允许一次重置。

## 接线与配置

- `Main_rjmcmc_EE.m`：传入新参数，并在结束时检查完整历史合同。
- `rj_ee_options.m`：增加重置、再填充、后重置更新间隔等参数。
- `Run_sequential_EE.m`：E6默认入口。

## 明确未修改

- `Birth.m`、`Death.m`、`Move.m`、`Change.m`；
- `RJ_C_mian.m`；
- 模型维数先验、速度/深度先验、似然和温度定义；
- EE接受率 `ee_dim_logaccept.m`；
- 原反演绘图函数。

静态哈希审计保存在 `docs/E5_STATIC_AUDIT.json`，E6流程审计保存在
`docs/E6_STATIC_AUDIT.json`。这些审计不能代替 MATLAB 自测、真实正演检查或
多种子收敛验证。
