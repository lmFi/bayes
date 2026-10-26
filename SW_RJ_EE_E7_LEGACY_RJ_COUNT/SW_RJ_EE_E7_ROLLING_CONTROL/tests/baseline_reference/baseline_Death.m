function [nuclei_depths, nuclei_vs, forward_model, like, npt, Num] = ...
    baseline_Death(nuclei_vs, nuclei_depths, like, npt, priors, sigma, Num, out, ...
    data_mode, fit_error, beta, forward_model_current)
%DEATH Remove one floating nucleus while preserving the complete chain state.
% The deleted floating nucleus is selected uniformly.  This selection factor
% is paired with the unordered-set log(npt!) term in logprior_model_state.

    for label={'birth','death'}
        for reason={'limit','bounds','prior','forward','mh_reject','accepted','disabled'}
            field=[label{1} '_' reason{1}];
            if ~isfield(Num,field), Num.(field)=0; end
        end
    end
    forward_model = forward_model_current;
    Num.PD = Num.PD + 1;

    if npt <= priors.npt_min || npt <= 0
        Num=rj_count_reason(Num,'death','limit');
        return;
    end

    nuclei_vs_prop = nuclei_vs;
    nuclei_depths_prop = nuclei_depths;
    npt_prop = npt - 1;
    Kcur = priors.num_layers + npt;
    ind = randi(npt) + priors.num_layers;

    deleted_vs = nuclei_vs(ind);
    deleted_depth = nuclei_depths(ind);
    nuclei_depths_prop(1:Kcur-1) = ...
        [nuclei_depths(1:ind-1); nuclei_depths(ind+1:Kcur)];
    nuclei_vs_prop(1:Kcur-1) = ...
        [nuclei_vs(1:ind-1); nuclei_vs(ind+1:Kcur)];

    node = whichnuclei(nuclei_depths_prop(1:Kcur-1), deleted_depth, priors);
    proposal_pdf = rj_birth_density(deleted_vs, nuclei_vs_prop(node), sigma);
    [~, depth_idx] = min(abs(priors.x - deleted_depth));
    prior_width = priors.vsmax_profile(depth_idx) - priors.vsmin_profile(depth_idx);
    if proposal_pdf <= 0 || prior_width <= 0
        Num=rj_count_reason(Num,'death','bounds');
        return;
    end

    if out ~= 1
        Num=rj_count_reason(Num,'death','disabled');
        return;
    end
    [thickness, density, vp, vs, priors_OK] = ...
        thicknesses_and_priors(nuclei_depths_prop, nuclei_vs_prop, npt_prop, priors);
    if priors_OK == 0
        Num=rj_count_reason(Num,'death','prior');
        return;
    end

    [forward_model_prop, like_prop] = ...
        forward_model_misfit(thickness, vp, vs, density, data_mode, fit_error);
    if ~isfinite(like_prop)
        Num=rj_count_reason(Num,'death','forward');
        return;
    end
    logprior_current = logprior_model_state( ...
        nuclei_depths, nuclei_vs, npt, priors, false);
    logprior_prop = logprior_model_state( ...
        nuclei_depths_prop, nuclei_vs_prop, npt_prop, priors, false);
    [~, p_death, ~] = rj_operation_probabilities(npt, priors);
    [p_birth_reverse, ~, ~] = rj_operation_probabilities(npt_prop, priors);
    depth_span = priors.depth_max - priors.depth_min;
    log_q_forward = log(p_death) - log(npt);
    log_q_reverse = log(p_birth_reverse) - log(depth_span) + log(proposal_pdf);
    log_jacobian = 0;
    log_alpha = ee_likelihood_delta(like, like_prop, beta, priors) + ...
        (logprior_prop - logprior_current) + ...
        (log_q_reverse - log_q_forward) + log_jacobian;

    if log(rand) < min(0, log_alpha)
        Num=rj_count_reason(Num,'death','accepted');
        Num.AD = Num.AD + 1;
        npt = npt_prop;
        nuclei_depths = nuclei_depths_prop;
        nuclei_vs = nuclei_vs_prop;
        like = like_prop;
        forward_model = forward_model_prop;
    else
        Num=rj_count_reason(Num,'death','mh_reject');
    end
end
