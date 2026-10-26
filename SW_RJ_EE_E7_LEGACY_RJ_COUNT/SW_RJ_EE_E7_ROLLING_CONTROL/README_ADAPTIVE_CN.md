# 旧版参考：E3/E4预热更新能量环＋近期FIFO历史

> 本文只记录E3/E4/E5的旧机制。当前E7请以 `README_先读我.md` 为准。

本压缩包已经从E3“无限全历史”更新为E4“近期FIFO历史”。具体差异先读
`README_RECENT_HISTORY_CN.md`。

## 运行
解压到新目录，MATLAB切换到该目录。不要覆盖旧项目。

```matlab
clear functions
run_self_tests
check_true_model_forward
file = Run_recent_history_EE;
inspect_adaptive_ee(file)
```

需要原环境的Python、numpy、disba。核心自测不需要disba。
当前交付环境没有MATLAB/Octave；已做MATLAB语法解析、源码差异和数据一致性检查，
没有声称已经运行MATLAB自测或实际反演。请先本地运行自测。

## 基线与默认实验
来自SW_RJ_EE_PAIRWISE完整代码，主程序采用用户20260918-005923上传版，
保留其实际斜先验 max(200,200+3z) .. min(1000,650+10z)。
六层观测直接使用seed30最新MAT保存的data，数值完全一致，不重新合成、不添加噪声。
沿用seed30、深度40m、npt=1..18（K=2..19）、Vp/Vs=1.732、sigma=max(0.01c,2)、
Birth混合20/100且小步80%、PT关闭、能量截断关闭。case_name='five'是兼容的旧名称。
Model=[400 500 600 300 700 900 3 5 6 3 10]仅为参考，未用它训练EE。

## 新日程
总40000轮，burn_in=20000。1001:3000首次校准，3001起保存近期FIFO历史，
4001起使用EE。重分环在4000,6000,...,18000轮结束发生，下一轮生效；
首次3000轮建立边界。后续校准使用max(1001,s-4000+1):s。
18000轮最终冻结，18001:20000留作过渡；20001起收集后验。
这个过渡时间不是收敛保证。

## 参数
rj_ee_options.m中新参数：
- ee_adapt_enable=true：开启本次方案。
- ee_adapt_window=4000：最近校准窗口，早期不足时截短。
- ee_adapt_interval=2000：绝对迭代数的整数倍更新，不是从3000开始加2000。
- ee_adapt_freeze=18000：即使不是interval整数倍也强制最后一次更新。

对照原晚分环40000轮：
```matlab
cfg=rj_ee_options;
cfg.ee_adapt_enable=false;
cfg.ee_calibration_start=14001;
cfg.ee_calibration_end=17000;
cfg.ee_jump_start=19001;
cfg.run_label='E2_fixed_late_control';
file=Main_rjmcmc_EE(cfg);
```
仅关闭adapt开关而不改日程，是“早分环固定边界”的另一个对照，不等于旧晚分环实验。
关闭EE可用cfg.enable_ee=false，其他参数固定。
旧ee_experiment_config/batch辅助函数保留供兼容，但本次请使用上面的明确配置入口。

## 实现与不变量
- Birth/Death/Move/Change及原绘图文件逐字节保留。
- EE仍为似然能量，原有先验不回火，接受率计算函数不改。
- ee_adaptive_update维护EE.archive{t}完整时间档案；EE.rings{t,k}仅含档案索引。
- 相同状态的停留重复不去重；采用严格FIFO，不抽稀、不按失配挑选。
- 每轮所有链完成后保存一次；当前轮条目只能从下一轮被抽到。
- 重分环使用已有ee_calibrate_pair：成对分位数及供体稀疏合并。
- 历史全部重新归环，不调用正演，历史条目数严格守恒。
- EE选中但不可用/拒绝仍为自循环，不补做RJ。
- 预热更新边界不消耗随机数。
- 固定分环分支保留原结构与抽样顺序。

## 诊断
EE.edge_updates保存每个版本的边界、校准窗口、校准占用、重新归环后的历史占用。
EE.edge_epoch_history(s)是第s轮跳跃实际使用的版本；更新当轮仍记旧版本。
EE事件CSV新增EdgeEpoch。跨版本不要把同一个Ring编号当成同一能量区间。
ring_attempts/ring_accepts仅代表最后一个版本，其他版本保存在edge_updates。
全程累计跳跃计数不清零。现有ee_calibration表只显示最终校准；所有校准在MAT里。
save_history=false不保存archive/rings，但保存边界及事件诊断，不影响运行期历史。
每条链的候选档案容量由`ee_archive_window`限制；默认4000。

## 限制
这是借鉴EE.zip预热更新思想的工程版本，不是原论文逐字实现，也不构成有限历史收敛证明。
请比较相同种子/预算的固定边界对照，再使用多个独立种子。
接受率升高并不等于层位恢复或后验收敛改善。
