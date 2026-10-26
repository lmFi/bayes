# 交付验证记录（2026-09-15）

本记录区分已执行验证和随包提供但尚未执行的 MATLAB 测试。

## 已执行

1. MISS_HIT 0.9.44 静态检查：96 个 MATLAB 文件，UTF-8 输入，退出码 0，无语法/lint 诊断。`MATLAB_STATIC_LINT.json` 为原始机器输出。此检查不能替代 MATLAB 执行或 MathWorks Code Analyzer。
2. Python 独立离散平衡例子：两个不同固定分区下，理想供体流量不对称误差分别为 1.39e-17、2.78e-17。它不执行 MATLAB 代码，不证明有限历史 EE 收敛。
3. 两个数据文件均为 100×4；五层各模态有效点数 66/64/77，七层 66/69/84。五层数据逐元素（含 NaN 掩码）与用户最新五层 MAT 内 data 一致。
4. Python disba 0.7.0 直接真模型正演：五层最大绝对误差 5.12e-13 m/s；七层最大绝对误差 4.55e-13 m/s；全部有效观测点均有预测。使用 Dunkin、dc=0.005 km/s、Vp=2Vs、rho=0.31Vp^0.25，与保留的正演函数物理关系一致。环境 Python 3.12.14 / NumPy 2.5.3 / Numba 0.67.0；这不是用户 Windows/MATLAB/Python 3.11 环境的运行结果。完整逐模态记录见 `PYTHON_VALIDATION.json`。
5. 文件内容比对：TUNING 的 RJ 主更新、Move、Change、两个先验密度函数、层状转换、失配正演、PhaseDispersion、后验收集及原三张反演绘图函数字节一致。`Birth/Death` 的差异仅为可关闭 A 深度提议及对应反向密度，见 `CHANGES.patch`。完整文件差异状态见 `BASELINE_MANIFEST.json`。

## 尚未执行

当前环境没有 MATLAB 或 Octave。`run_self_tests`、MATLAB→Python 集成、MAT 文件/CSV 写出、图形渲染以及真实 20000 轮反演，均需在用户 MATLAB 中运行。不能据静态检查或 Python 直接正演声称上述项目已经通过。

随包 MATLAB 自检包含：原 DIM/v4 合同测试、混合高斯密度、A 深度混合密度及随机数流、A 关闭对 TUNING 参考更新的逐轮回归、链对分区路由、冻结后历史、完整状态转移、空环自环、结构诊断不改变随机数流、校准合并及并列值、禁用 EE 的空事件输出、配置和数据读取。

`tests/dim_fixture/forward_model_misfit.m` 只用于不依赖 Python 的测试，不能加入反演运行路径。测试运行后会恢复路径和随机数状态。工程入口会检查关键函数是否被其他目录覆盖。

性能结论待 EE 开关/分环对照实验。相同种子不表示启用 EE 后仍使用完全相同的随机序列。请同时比较采样时间、能量/模型分布稳定性、后验结构及不同种子的一致性；不要只选择最像真模型的一次运行。
