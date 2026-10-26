function [best_mode, forward_model_best, is_updated] = best_mode_update(best_mode, chain, priors_OK, forward_model, forward_model_best)
% BEST_MODE_UPDATE
%   每次迭代：若主链更优则刷新 best_mode；同时保证 best_mode 字段永远存在。
%
% 输入：
%   best_mode           : struct（可以为空或缺字段，函数会自动补齐）
%   chain               : struct（必须含 nuclei_depths / nuclei_vs / like / npt）
%   priors_OK           : 0/1（若为0，则不更新 best，但仍保证字段存在）
%   forward_model       : [nd x (dc_num+1) x T]
%   forward_model_best  : [nd x (dc_num+1)]（可传空，函数会补一个默认）
%
% 输出：
%   best_mode           : 更新后的 best_mode（字段齐全）
%   forward_model_best  : 若更新则同步刷新，否则保持不变
%   is_updated          : true/false，标记本次是否刷新了 best

    is_updated = false;

    % --------- 1) 兜底：确保 forward_model_best 总有值 ----------
    if nargin < 5 || isempty(forward_model_best)
        forward_model_best = forward_model(:, :, 1);
    end

    % --------- 2) 兜底：best_mode 为空或缺字段时，先补齐 ----------
    if nargin < 1 || isempty(best_mode)
        best_mode = struct();
    end

    if ~isfield(best_mode, 'like_best')   || isempty(best_mode.like_best),   best_mode.like_best   = chain.like;         end
    if ~isfield(best_mode, 'depths_best') || isempty(best_mode.depths_best), best_mode.depths_best = chain.nuclei_depths; end
    if ~isfield(best_mode, 'vs_best')     || isempty(best_mode.vs_best),     best_mode.vs_best     = chain.nuclei_vs;     end
    if ~isfield(best_mode, 'npt_best')    || isempty(best_mode.npt_best),    best_mode.npt_best    = chain.npt;           end

    % 兼容字段
    if ~isfield(best_mode, 'nuclei_depths_best') || isempty(best_mode.nuclei_depths_best)
        best_mode.nuclei_depths_best = best_mode.depths_best;
    end
    if ~isfield(best_mode, 'nuclei_vs_best') || isempty(best_mode.nuclei_vs_best)
        best_mode.nuclei_vs_best = best_mode.vs_best;
    end

    % --------- 3) 若 priors_OK 不通过：不更新 best，但字段已保证存在 ----------
    if nargin >= 3 && priors_OK == 0
        return;
    end

    % --------- 4) 更优则更新 ----------
    if chain.like < best_mode.like_best
        best_mode.like_best   = chain.like;
        best_mode.depths_best = chain.nuclei_depths;
        best_mode.vs_best     = chain.nuclei_vs;
        best_mode.npt_best    = chain.npt;

        % 兼容字段同步
        best_mode.nuclei_depths_best = chain.nuclei_depths;
        best_mode.nuclei_vs_best     = chain.nuclei_vs;

        forward_model_best = forward_model(:, :, 1);
        is_updated = true;
    end
end
