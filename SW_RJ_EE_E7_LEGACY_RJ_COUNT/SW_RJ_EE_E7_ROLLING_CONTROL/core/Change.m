function [nuclei_depths, nuclei_vs, forward_model, like, npt, Num] = ...
    Change(nuclei_vs, nuclei_depths, like, npt, priors, sigma, Num, out, ...
    data_mode, fit_error, beta, x, forward_model_current)
%CHANGE Perturb one Vs value using a symmetric, unclipped Gaussian proposal.

    forward_model = forward_model_current;
    Num.PV = Num.PV + 1;
    nuclei_vs_prop = nuclei_vs;
    nuclei_depths_prop = nuclei_depths;

    ind = randi(npt + priors.num_layers);
    [~, depth_idx] = min(abs(x - nuclei_depths(ind)));
    new_vs = nuclei_vs(ind) + randn * sigma.change_vs;
    if ~isfinite(new_vs) || new_vs < priors.vsmin_profile(depth_idx) || ...
            new_vs > priors.vsmax_profile(depth_idx)
        return;
    end
    nuclei_vs_prop(ind) = new_vs;

    if out ~= 1
        return;
    end
    [thickness, density, vp, vs, priors_OK] = ...
        thicknesses_and_priors(nuclei_depths_prop, nuclei_vs_prop, npt, priors);
    if priors_OK == 0
        return;
    end

    [forward_model_prop, like_prop] = ...
        forward_model_misfit(thickness, vp, vs, density, data_mode, fit_error);
    logprior_current = logprior_model_state( ...
        nuclei_depths, nuclei_vs, npt, priors, false);
    logprior_prop = logprior_model_state( ...
        nuclei_depths_prop, nuclei_vs_prop, npt, priors, false);
    log_alpha = ee_likelihood_delta(like, like_prop, beta, priors) + ...
        (logprior_prop - logprior_current);

    if log(rand) < min(0, log_alpha)
        Num.AcV = Num.AcV + 1;
        nuclei_vs = nuclei_vs_prop;
        like = like_prop;
        forward_model = forward_model_prop;
    end
end
