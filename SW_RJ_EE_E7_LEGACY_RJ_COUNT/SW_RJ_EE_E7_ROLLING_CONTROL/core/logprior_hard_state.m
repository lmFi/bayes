function logp = logprior_hard_state(depths_full, vs_full, npt, priors)
%LOGPRIOR_HARD_STATE Log density of the depth-dependent uniform Vs prior.

    K = priors.num_layers + npt;
    logp = 0;
    for i = 1:K
        [~, depth_index] = min(abs(priors.x - depths_full(i)));
        lower = priors.vsmin_profile(depth_index);
        upper = priors.vsmax_profile(depth_index);
        width = upper - lower;
        if ~isfinite(width) || width <= 0 || ~isfinite(vs_full(i)) || ...
                vs_full(i) < lower || vs_full(i) > upper
            logp = -Inf;
            return;
        end
        logp = logp - log(width);
    end
end
