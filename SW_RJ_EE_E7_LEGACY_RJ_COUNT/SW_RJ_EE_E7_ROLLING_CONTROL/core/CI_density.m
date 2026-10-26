function [CI_density_limitN, CI_density_limit] = ...
    CI_density(result, variable, dis, x, y) %#ok<INUSD>
%CI_DENSITY Restrict and normalize the posterior density using Vs samples.
% The 95% equal-tailed bounds come directly from the retained cold-chain
% profiles, rather than from the former MINI_vs/MAXI_vs extreme-value cache.

    if isfield(result, 'vs_lower') && isfield(result, 'vs_upper')
        lower = result.vs_lower(:);
        upper = result.vs_upper(:);
    elseif isfield(result, 'vs_all') && ~isempty(result.vs_all)
        bounds = quantile(result.vs_all, [0.025, 0.975], 1);
        lower = bounds(1, :).';
        upper = bounds(2, :).';
    else
        error('CI_density:MissingPosteriorSamples', ...
            '需要 result.vs_all 或预先计算的 result.vs_lower/vs_upper。');
    end

    n_depth_bins = size(result.CI_density, 1);
    if numel(lower) == n_depth_bins + 1
        lower = 0.5 * (lower(1:end-1) + lower(2:end));
        upper = 0.5 * (upper(1:end-1) + upper(2:end));
    elseif numel(lower) ~= n_depth_bins
        error('CI_density:DepthSizeMismatch', ...
            '可信区间长度 %d 与密度深度维数 %d 不兼容。', ...
            numel(lower), n_depth_bins);
    end

    velocity_centers = 0.5 * (y(1:end-1) + y(2:end));
    if numel(velocity_centers) ~= size(result.CI_density, 2)
        error('CI_density:VelocitySizeMismatch', ...
            '速度网格中心数与密度矩阵列数不一致。');
    end

    credible_mask = velocity_centers(:).' >= lower & ...
        velocity_centers(:).' <= upper;
    CI_density_limit = result.CI_density .* credible_mask;

    row_sum = sum(CI_density_limit, 2, 'omitnan');
    CI_density_limitN = nan(size(CI_density_limit));
    good = row_sum > 0 & isfinite(row_sum);
    CI_density_limitN(good, :) = ...
        CI_density_limit(good, :) ./ row_sum(good);
end
