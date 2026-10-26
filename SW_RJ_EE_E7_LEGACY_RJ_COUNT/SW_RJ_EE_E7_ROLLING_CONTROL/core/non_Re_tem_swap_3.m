function [nuclei_depths, nuclei_vs, npt, like, forward_model] = ...
    non_Re_tem_swap_3(nuclei_depths, nuclei_vs, npt, like, beta, T, iter, forward_model, priors, floors)
%NON_RE_TEM_SWAP_3 Odd-even swaps; only the likelihood is tempered.

    if nargin < 8
        forward_model = [];
    end
    if nargin < 7 || isempty(iter)
        iter = randi(2);
    end
    if nargin<10, floors=-Inf(1,T); end
    first = 1 + mod(iter, 2);
    for i = first:2:(T-1)
        j = i + 1;
        log_alpha = ee_dim_logaccept(like(i),like(j),beta(i),beta(j),floors(i),floors(j));
        if log(rand) < min(0, log_alpha)
            nuclei_depths(:, [i, j]) = nuclei_depths(:, [j, i]);
            nuclei_vs(:, [i, j]) = nuclei_vs(:, [j, i]);
            npt([i, j]) = npt([j, i]);
            like([i, j]) = like([j, i]);
            if ~isempty(forward_model)
                forward_model(:, :, [i, j]) = forward_model(:, :, [j, i]);
            end
        end
    end
end
