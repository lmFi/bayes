function [nuclei_depths, nuclei_vs, npt, like, forward_model, ...
    ee_selected, EE] = ee_jump(nuclei_depths, nuclei_vs, npt, like, ...
    forward_model, beta, EE, s, t)
%EE_JUMP Optionally apply one supplemental EE update after local RJ.
%
% E5 composes two invariant kernels in sequence:
%   K_i = K_RJ * [(1-p_EE) I + p_EE K_EE].
% Main_rjmcmc_EE calls this routine only AFTER every chain has completed its
% mandatory local RJ update.  The output ee_selected is true exactly when
% the EE coin selected this supplemental branch.  It never controls whether
% RJ is run.
%
% If EE is disabled, not scheduled, or not selected, ee_selected is false.
% If selected but unavailable/rejected, the post-local state is retained.
% The hottest chain has no donor and therefore never selects EE.
%
% The likelihood-tempered target is
%   pi_i(m) proportional to p(m)*exp(-beta_i*max(like(m),H_i)).
% With the same untempered prior on adjacent chains, the EE log ratio is
%   log(r) = h_i(x)-h_i(y)+h_j(y)-h_j(x), j=i+1.

    ee_selected = false;
    T = size(nuclei_vs, 2);

    if t < 1 || t > T || t ~= round(t)
        error('ee_jump:InvalidChainIndex', ...
            't must be an integer between 1 and the number of chains.');
    end

    % There is no hotter donor for the hottest chain.
    if t == T || ~EE.enable || isempty(EE.edges) || ...
            s < EE.jump_start || mod(s, EE.jump_interval) ~= 0
        return;
    end

    % Choose the supplemental EE kernel versus identity.  Local RJ has
    % already been completed by the caller and is never skipped.
    if rand >= EE.jump_probability
        return;
    end
    EE.jump_triggered(t) = EE.jump_triggered(t) + 1;
    ee_selected = true;
    EE.jump_history(s, t) = int8(2); % selected but unavailable unless overwritten

    beta = beta(:).';
    like_row = like(:).';
    if ~isfinite(like_row(t))
        EE.jump_unavailable(t) = EE.jump_unavailable(t) + 1;
        return;
    end

    donor = t + 1;
    pair_edges = ee_edges_for_chain(EE,donor);
    k = ee_dim_bin(like_row(t), pair_edges);
    EE.current_energy(s,t) = like_row(t);
    EE.selected_ring(s,t) = k;
    count = EE.ring_count(donor, k);
    EE.donor_count_at_selection(s,t)=count;
    EE.current_npt(s,t)=npt(t);
    if count < EE.min_ring_size
        EE.unavailable_reason(s,t)=uint8(1); % donor shortage
        % No usable proposal: retain the state produced by local RJ.
        EE.jump_unavailable(t) = EE.jump_unavailable(t) + 1;
        return;
    end

    draw = randi(count);
    if isfield(EE,'adapt_enable') && EE.adapt_enable
        idx=EE.rings{donor,k}(draw);
        y=EE.archive{donor}(idx);
    else
        y=EE.rings{donor,k}(draw);
    end
    if ~isfield(y, 'like') || ~isfinite(y.like) || ...
            ~isequal(size(y.depths), size(nuclei_depths(:, t))) || ...
            ~isequal(size(y.vs), size(nuclei_vs(:, t))) || ...
            ~isequal(size(y.forward_model), size(forward_model(:, :, t)))
        EE.unavailable_reason(s,t)=uint8(2); % invalid archived state
        EE.jump_unavailable(t) = EE.jump_unavailable(t) + 1;
        return;
    end

    EE.jump_proposed(t) = EE.jump_proposed(t) + 1;

    if y.iteration >= s
        error('EE:DIMFutureHistory','EE candidate must come from a completed past iteration.');
    end
    if ee_dim_bin(y.like, pair_edges) ~= k
        error('EE:DIMWrongRing','Candidate is not in the same fixed energy ring.');
    end
    EE.candidate_energy(s,t) = y.like;
    EE.candidate_iteration(s,t) = y.iteration;
    EE.ring_attempts(t,k) = EE.ring_attempts(t,k)+1;
    current_npt = npt(t);
    EE.candidate_npt(s,t)=y.npt;
    if isfield(EE,'diagnostic_priors') && ~isempty(EE.diagnostic_priors)
        [EE.profile_rms_delta(s,t),EE.profile_max_delta(s,t)]=ee_profile_distance( ...
            nuclei_depths(:,t),nuclei_vs(:,t),npt(t),y.depths,y.vs,y.npt, ...
            EE.diagnostic_priors,EE.diagnostic_grid);
    end
    EE.jump_candidate_energy_delta(s, t) = y.like - like_row(t);
    EE.jump_candidate_npt_delta(s, t) = y.npt - current_npt;
    is_crossdimensional = y.npt ~= current_npt;
    if is_crossdimensional
        EE.jump_crossdim_proposed(t) = ...
            EE.jump_crossdim_proposed(t) + 1;
    end

    log_alpha = ee_dim_logaccept(like_row(t), y.like, beta(t), beta(donor), ...
        EE.energy_floors(t), EE.energy_floors(donor));
    EE.log_acceptance(s,t) = log_alpha;

    if log(rand) < min(0, log_alpha)
        nuclei_depths(:, t) = y.depths;
        nuclei_vs(:, t) = y.vs;
        npt(t) = y.npt;
        like_row(t) = y.like;
        forward_model(:, :, t) = y.forward_model;
        EE.jump_accepted(t) = EE.jump_accepted(t) + 1;
        EE.ring_accepts(t,k) = EE.ring_accepts(t,k)+1;
        if is_crossdimensional
            EE.jump_crossdim_accepted(t) = ...
                EE.jump_crossdim_accepted(t) + 1;
        end
        EE.jump_history(s, t) = int8(1);
    else
        % Rejection retains the state produced by local RJ.
        EE.jump_history(s, t) = int8(-1);
    end

    if isrow(like)
        like(1, 1:T) = like_row(1:T);
    else
        like(1:T, 1) = like_row(1:T).';
    end
end
