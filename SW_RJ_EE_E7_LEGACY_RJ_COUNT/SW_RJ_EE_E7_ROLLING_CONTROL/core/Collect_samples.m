function [result, variable, priors] = Collect_samples( ...
    dis, priors, variable, result, x, chain, best_mode, n_tail, N) %#ok<INUSD>
%COLLECT_SAMPLES Accumulate one retained cold-chain sample.

    variable.counter_basic = variable.counter_basic + 1;
    sample_index = variable.counter_basic;
    K = priors.num_layers + chain.npt;
    active_depths = chain.nuclei_depths(1:K);
    active_vs = chain.nuclei_vs(1:K);

    if sample_index > size(result.vs_all, 1)
        error('Collect_samples:CapacityExceeded', ...
            'Retained sample %d exceeds the preallocated capacity %d.', ...
            sample_index, size(result.vs_all, 1));
    end

    for i = 1:dis
        index = whichnuclei(active_depths, x(i), priors);
        current_vs = active_vs(index);
        result.AV(i) = result.AV(i) + current_vs;

        result.vs_all(sample_index, i) = current_vs;
    end

    if K <= size(result.nnucleihist, 1)
        result.nnucleihist(K) = result.nnucleihist(K) + 1;
    end

    sorted_depths = sort(active_depths);
    for j = 1:(K - 1)
        variable.counter_auxiliary = variable.counter_auxiliary + 1;
        result.change_points(variable.counter_auxiliary) = ...
            0.5 * (sorted_depths(j + 1) + sorted_depths(j));
    end

    result.CI_density = result.CI_density + N;
    if ~isfield(result, 'forward_model_all') || isempty(result.forward_model_all)
        result.forward_model_all = nan( ...
            size(chain.forward_model, 1), size(chain.forward_model, 2), ...
            size(result.vs_all, 1));
    end
    result.forward_model_all(:, :, sample_index) = chain.forward_model;
end
