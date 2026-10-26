function forward_model = ensure_forward_model(forward_model, nuclei_depths, nuclei_vs, ...
    npt, priors, data_mode, fit_error, stored_like)
%ENSURE_FORWARD_MODEL Return a response consistent with the supplied state.

    expected_size = [numel(data_mode.freq), data_mode.dc_num + 1];
    response_missing = isempty(forward_model) || ...
        ~isequal(size(forward_model), expected_size) || ...
        all(~isfinite(forward_model(:, 2:end)) | forward_model(:, 2:end) == 0, 'all');

    if ~response_missing
        return;
    end

    [thickness, density, vp, vs, priors_OK] = ...
        thicknesses_and_priors(nuclei_depths, nuclei_vs, npt, priors);
    if priors_OK == 0
        error('ensure_forward_model:InvalidState', ...
            'The current chain state violates the hard prior.');
    end

    [forward_model, recomputed_like] = ...
        forward_model_misfit(thickness, vp, vs, density, data_mode, fit_error);

    tolerance = 1e-8 * max(1, abs(stored_like));
    if isfinite(stored_like) && isfinite(recomputed_like) && ...
            abs(recomputed_like - stored_like) > tolerance
        warning('ensure_forward_model:MisfitMismatch', ...
            'Stored and recomputed negative log-likelihood differ by %.6g.', ...
            abs(recomputed_like - stored_like));
    end
end
