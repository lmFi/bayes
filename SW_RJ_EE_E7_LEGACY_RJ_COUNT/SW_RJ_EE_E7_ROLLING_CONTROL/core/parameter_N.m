function N = parameter_N(dis, nuclei_depths, nuclei_vs, priors, variable, ...
    x_edges, y_edges, npt) %#ok<INUSD>
%PARAMETER_N Bin one cold-chain profile at depth-bin centres.

    if size(nuclei_depths, 2) > 1
        nuclei_depths = nuclei_depths(:, 1);
        nuclei_vs = nuclei_vs(:, 1);
    end

    K = priors.num_layers + npt;
    active_depths = nuclei_depths(1:K);
    active_vs = nuclei_vs(1:K);
    z_centers = 0.5 * (x_edges(1:end-1) + x_edges(2:end));
    vs_profile = zeros(size(z_centers));

    for i = 1:numel(z_centers)
        index = whichnuclei(active_depths, z_centers(i), priors);
        vs_profile(i) = active_vs(index);
    end

    N = histcounts2(z_centers, vs_profile, x_edges, y_edges);
end
