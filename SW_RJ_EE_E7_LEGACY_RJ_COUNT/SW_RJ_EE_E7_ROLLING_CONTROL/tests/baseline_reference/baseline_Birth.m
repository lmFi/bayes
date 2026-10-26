function [nuclei_depths, nuclei_vs, forward_model, like, npt, Num] = ...
    baseline_Birth(nuclei_vs, nuclei_depths, like, npt, priors, sigma, Num, out, ...
    data_mode, fit_error, beta, x, forward_model_current)
%BIRTH Add one floating nucleus while preserving the complete chain state.
% Floating nuclei form an unordered exchangeable set.  The reverse move
% deletes one of npt_prop nuclei uniformly; its 1/npt_prop factor is paired
% with log(npt!) in logprior_model_state.

    for label={'birth','death'}
        for reason={'limit','bounds','prior','forward','mh_reject','accepted','disabled'}
            field=[label{1} '_' reason{1}];
            if ~isfield(Num,field), Num.(field)=0; end
        end
    end
    forward_model = forward_model_current;
    Num.PB = Num.PB + 1;

    if npt >= priors.npt_max
        Num=rj_count_reason(Num,'birth','limit');
        return;
    end

    nuclei_vs_prop = nuclei_vs;
    nuclei_depths_prop = nuclei_depths;
    npt_prop = npt + 1;
    knew = priors.num_layers + npt_prop;

    new_depth = priors.depth_min + rand * ...
        (priors.depth_max - priors.depth_min);
    nuclei_depths_prop(knew) = new_depth;

    [~, depth_idx] = min(abs(x - new_depth));
    vs_min = priors.vsmin_profile(depth_idx);
    vs_max = priors.vsmax_profile(depth_idx);

    ind = whichnuclei(nuclei_depths(1:knew-1), new_depth, priors);
    width=sigma.birth_vs;
    if isfield(sigma,'birth_mixture') && sigma.birth_mixture
        if rand<sigma.birth_small_weight, width=sigma.birth_small; end
    end
    new_vs = nuclei_vs(ind) + randn * width;

    % A clipped Gaussian is not symmetric and creates point masses at bounds.
    if ~isfinite(new_vs) || new_vs < vs_min || new_vs > vs_max
        Num=rj_count_reason(Num,'birth','bounds');
        return;
    end
    nuclei_vs_prop(knew) = new_vs;

    proposal_pdf = rj_birth_density(new_vs, nuclei_vs(ind), sigma);
    if proposal_pdf <= 0 || vs_max <= vs_min
        Num=rj_count_reason(Num,'birth','bounds');
        return;
    end

    if out ~= 1
        Num=rj_count_reason(Num,'birth','disabled');
        return;
    end
    [thickness, density, vp, vs, priors_OK] = ...
        thicknesses_and_priors(nuclei_depths_prop, nuclei_vs_prop, npt_prop, priors);
    if priors_OK == 0
        Num=rj_count_reason(Num,'birth','prior');
        return;
    end

    [forward_model_prop, like_prop] = ...
        forward_model_misfit(thickness, vp, vs, density, data_mode, fit_error);
    if ~isfinite(like_prop)
        Num=rj_count_reason(Num,'birth','forward');
        return;
    end

    logprior_current = logprior_model_state( ...
        nuclei_depths, nuclei_vs, npt, priors, false);
    logprior_prop = logprior_model_state( ...
        nuclei_depths_prop, nuclei_vs_prop, npt_prop, priors, false);
    [p_birth, ~, ~] = rj_operation_probabilities(npt, priors);
    [~, p_death_reverse, ~] = rj_operation_probabilities(npt_prop, priors);
    depth_span = priors.depth_max - priors.depth_min;
    log_q_forward = log(p_birth) - log(depth_span) + log(proposal_pdf);
    log_q_reverse = log(p_death_reverse) - log(npt_prop);
    log_jacobian = 0;
    log_alpha = ee_likelihood_delta(like, like_prop, beta, priors) + ...
        (logprior_prop - logprior_current) + ...
        (log_q_reverse - log_q_forward) + log_jacobian;
    if log(rand) < min(0, log_alpha)
        Num=rj_count_reason(Num,'birth','accepted');
        Num.AB = Num.AB + 1;
        npt = npt_prop;
        nuclei_depths = nuclei_depths_prop;
        nuclei_vs = nuclei_vs_prop;
        like = like_prop;
        forward_model = forward_model_prop;
    else
        Num=rj_count_reason(Num,'birth','mh_reject');
    end
end
