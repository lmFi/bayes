function [nuclei_depths, nuclei_vs, forward_model, like, npt, Num] = ...
    Move(nuclei_vs, nuclei_depths, like, npt, priors, sigma, Num, out, ...
    data_mode, fit_error, beta, forward_model_current)
%MOVE Perturb one nucleus depth and retain the current response on rejection.

    forward_model = forward_model_current;
    Num.PP = Num.PP + 1;
    nuclei_vs_prop = nuclei_vs;
    nuclei_depths_prop = nuclei_depths;
    ind = randi(npt + priors.num_layers);

    if priors.num_layers == 1 || ind > priors.num_layers
        nuclei_depths_prop(ind) = nuclei_depths(ind) + randn * sigma.move_depth;
    else
        if ind == 1
            top_of_layer = priors.depth_min;
            bottom_of_layer = priors.layer_depths(1);
        elseif ind < priors.num_layers
            top_of_layer = priors.layer_depths(ind - 1);
            bottom_of_layer = priors.layer_depths(ind);
        else
            top_of_layer = priors.layer_depths(ind - 1);
            bottom_of_layer = priors.depth_max;
        end
        nuclei_depths_prop(ind) = top_of_layer + rand * (bottom_of_layer - top_of_layer);
    end

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
        Num.AP = Num.AP + 1;
        nuclei_depths = nuclei_depths_prop;
        like = like_prop;
        forward_model = forward_model_prop;
    end
end
