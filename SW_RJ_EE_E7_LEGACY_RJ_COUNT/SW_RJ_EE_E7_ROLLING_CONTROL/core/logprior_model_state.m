function logp = logprior_model_state(depths, vs, npt, priors, include_dix)
%LOGPRIOR_MODEL_STATE Un-tempered prior. The state-measure switch controls n!.
% Default model:
%   - npt is discrete-uniform on [npt_min,npt_max];
%   - floating-nucleus depths are exchangeable iid uniform draws;
%   - Vs uses the depth-dependent uniform hard prior;
%   - the fixed-grid Dix penalty is optional.
% Custom priors may be supplied as priors.log_p_npt and priors.log_p_depth
% function handles (or log_p_npt as a vector indexed from npt_min).

    if nargin < 5
        include_dix = false;
    end
    if npt < priors.npt_min || npt > priors.npt_max
        logp = -Inf;
        return;
    end

    if isfield(priors, 'log_p_npt') && isa(priors.log_p_npt, 'function_handle')
        logp = priors.log_p_npt(npt);
    elseif isfield(priors, 'log_p_npt') && isnumeric(priors.log_p_npt)
        index = npt - priors.npt_min + 1;
        if index < 1 || index > numel(priors.log_p_npt)
            logp = -Inf;
            return;
        end
        logp = priors.log_p_npt(index);
    else
        logp = -log(priors.npt_max - priors.npt_min + 1);
    end

    % Legacy initial code omitted log(npt!), leaving Death's 1/npt factor
    % in the RJ acceptance ratio. E7's unordered option restores that factor
    % and is needed when log_p_npt is intended as a uniform physical count prior.
    state_measure = 'labelled_iid_uniform_depth';
    if isfield(priors, 'rj_state_measure') && ...
            ~isempty(priors.rj_state_measure)
        state_measure = char(priors.rj_state_measure);
    end
    if ~strcmpi(state_measure, 'unordered_iid_uniform_depth') && ...
            ~strcmpi(state_measure, 'labelled_iid_uniform_depth')
        error('logprior_model_state:UnsupportedStateMeasure', ...
            'Unknown priors.rj_state_measure.');
    end
    if strcmpi(state_measure, 'unordered_iid_uniform_depth')
        logp = logp + gammaln(npt + 1);
    end

    Kfixed = priors.num_layers;
    floating_depths = depths(Kfixed + (1:npt));
    if isfield(priors, 'log_p_depth') && isa(priors.log_p_depth, 'function_handle')
        logp = logp + priors.log_p_depth(floating_depths, npt, priors);
    else
        depth_span = priors.depth_max - priors.depth_min;
        if depth_span <= 0 || any(floating_depths < priors.depth_min) || ...
                any(floating_depths > priors.depth_max)
            logp = -Inf;
            return;
        end
        logp = logp - npt * log(depth_span);
    end

    logp = logp + logprior_hard_state(depths, vs, npt, priors);
    if include_dix
        logp = logp + logprior_dix_state(depths, vs, npt, priors);
    end
end
