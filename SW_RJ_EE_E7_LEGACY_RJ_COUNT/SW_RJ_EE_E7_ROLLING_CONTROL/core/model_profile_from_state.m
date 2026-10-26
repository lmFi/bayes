function profile = model_profile_from_state(depths, vs, npt, priors, x)
%MODEL_PROFILE_FROM_STATE Project one sampled nucleus state onto a depth grid.

    K = priors.num_layers + npt;
    active_depths = depths(1:K);
    active_vs = vs(1:K);
    profile = zeros(size(x));
    for i = 1:numel(x)
        index = whichnuclei(active_depths, x(i), priors);
        profile(i) = active_vs(index);
    end
end
