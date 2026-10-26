function [nuclei_vs, nuclei_depths, npt, like, like_best, priors_OK, forward_model] = ...
    initialize_chain(npt_init, priors, data_mode, fit_error, ...
    nuclei_vs, nuclei_depths, npt, like, T, x)
%INITIALIZE_CHAIN Generate a valid finite initial state and copy it to all chains.

    max_attempts = 100;
    priors_OK = false;
    like0 = Inf;
    forward0 = [];

    for attempt = 1:max_attempts
        [vs0, depths0, npt0, ok0, like0, forward0] = ...
            Init_L(npt_init, priors, data_mode, fit_error, x);
        if ok0 && isfinite(like0) && ~isempty(forward0)
            priors_OK = true;
            break;
        end
    end

    if ~priors_OK
        error('initialize_chain:NoFiniteInitialState', ...
            '无法在 %d 次尝试内生成具有有限正演响应的初始模型。', max_attempts);
    end

    nuclei_vs(:, 1) = vs0;
    nuclei_depths(:, 1) = depths0;
    npt(1) = npt0;
    like(1) = like0;

    nuclei_vs = repmat(nuclei_vs(:, 1), 1, T);
    nuclei_depths = repmat(nuclei_depths(:, 1), 1, T);
    npt = repmat(npt(1), 1, T);
    like = repmat(like(1), 1, T);
    forward_model = repmat(forward0, 1, 1, T);
    like_best = like0;
end
