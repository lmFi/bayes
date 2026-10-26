function test_rj_count_prior_balance
%TEST_RJ_COUNT_PRIOR_BALANCE Verify the npt combinatorial correction.
% With a uniform npt prior and birth variables proposed from their priors,
% the prior-only birth/death log acceptance ratio must be zero away from the
% dimension boundaries.

    priors.npt_min = 1;
    priors.npt_max = 8;
    priors.num_layers = 1;
    priors.depth_min = 0;
    priors.depth_max = 10;
    priors.x = linspace(0, 10, 101).';
    priors.vsmin_profile = zeros(size(priors.x));
    priors.vsmax_profile = ones(size(priors.x));
    priors.rj_state_measure = 'unordered_iid_uniform_depth';
    priors.log_p_npt = repmat(-log(8), 1, 8);
    priors.proposal_prob_birth = 1/3;
    priors.proposal_prob_death = 1/3;
    priors.proposal_prob_move = 1/3;

    capacity = priors.num_layers + priors.npt_max;
    depth_span = priors.depth_max - priors.depth_min;
    vs_width = 1;

    for npt = priors.npt_min:(priors.npt_max - 1)
        depths = zeros(capacity, 1);
        velocities = zeros(capacity, 1);
        depths(1) = 5;
        velocities(1) = 0.5;
        depths(2:npt+1) = linspace(0.5, 9.5, npt);
        velocities(2:npt+1) = 0.5;

        depths_prop = depths;
        velocities_prop = velocities;
        depths_prop(npt + 2) = 0.25;
        velocities_prop(npt + 2) = 0.5;

        logprior_current = logprior_model_state( ...
            depths, velocities, npt, priors, false);
        logprior_prop = logprior_model_state( ...
            depths_prop, velocities_prop, npt + 1, priors, false);

        [p_birth, ~, ~] = rj_operation_probabilities(npt, priors);
        [~, p_death_reverse, ~] = ...
            rj_operation_probabilities(npt + 1, priors);

        % Test with matched uniform proposals for the new depth and Vs.
        log_q_forward = log(p_birth) - log(depth_span) - log(vs_width);
        log_q_reverse = log(p_death_reverse) - log(npt + 1);
        log_alpha = (logprior_prop - logprior_current) + ...
            (log_q_reverse - log_q_forward);

        assert(abs(log_alpha) < 1e-12, ...
            'Uniform npt prior is not balanced at npt=%d.', npt);
    end

    fprintf('  PASS: RJ count-prior balance\n');
end
