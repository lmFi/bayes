function [best_mode, forward_model_best] = best_mode_init(nuclei_depths, nuclei_vs, npt, like, forward_model)
% BEST_MODE_INIT
%   初始化 best_mode 的所有关键字段，保证 Collect_samples 永远不会缺字段。
%
% 输入：
%   nuclei_depths, nuclei_vs : [priors.npt_max+priors.num_layers x T]
%   npt, like                : [1 x T] 或 [T x 1]
%   forward_model            : [nd x (dc_num+1) x T]
%
% 输出：
%   best_mode                : struct，字段齐全（like_best / depths_best / vs_best / npt_best 等）
%   forward_model_best       : [nd x (dc_num+1)]，主链(t=1)的前向响应

    % 统一成标量
    like1 = like(1);
    npt1  = npt(1);

    best_mode = struct();

    % 关键字段（Collect_samples 依赖）
    best_mode.like_best   = like1;
    best_mode.depths_best = nuclei_depths(:, 1);
    best_mode.vs_best     = nuclei_vs(:, 1);
    best_mode.npt_best    = npt1;

    % 兼容字段（你工程里有时会用到）
    best_mode.nuclei_depths_best = nuclei_depths(:, 1);
    best_mode.nuclei_vs_best     = nuclei_vs(:, 1);

    % 避免后面绘图 forward_model_best 未定义
    forward_model_best = forward_model(:, :, 1);
end
