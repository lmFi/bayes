# 初始版 Birth/Death 接受率对照

此包将 `cfg.rj_state_measure` 默认设置为 `labelled_iid_uniform_depth`，
即初始版 `logprior_model_state.m` 的计算方式：不加入 `log(npt!)`。
因此在其余状态和提议完全相同时，Birth 对数接受比原 E7 少 `log(npt+1)`，
Death 多 `log(npt)`。Change 和 Move 的先验比不变。

运行已有入口即可使用此默认值。若需恢复原 E7 的组合项：

```matlab
cfg = rj_ee_options('five','continuous');
cfg.rj_state_measure = 'unordered_iid_uniform_depth';
file = Main_rjmcmc_EE(cfg);
```

**用途限定**：初始版的组合因子不能保证 `npt_prior=[]` 表示物理层数的
均匀先验。浮动核的排列不改变 Voronoi 速度模型；用于正式后验推断时，
应优先审视原 E7 的 `unordered_iid_uniform_depth` 和层数先验平衡测试。

此外，本修改只切换组合项。E7 的观测文件、1% 误差、40 m 深度、四条链等
仍不同于初始压缩包。即使 EE、PT、混合 Birth 均关闭，结果也不会自动相同。

可先在 MATLAB 运行 `run_self_tests`。其中旧版组合项的对数差异由
`tests/test_legacy_count_factor.m` 检查；测试不替代实际反演对照。
