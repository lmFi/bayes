function result = initialize_result(dis, dis_y, priors, nsample, T, n_tail, n_keep) %#ok<INUSD>
%INITIALIZE_RESULT Preallocate inversion diagnostics and retained samples.

    if nargin < 7 || isempty(n_keep)
        % Backward compatibility for older drivers. Updated drivers pass the
        % exact retained count so no dynamic growth or trailing rows occur.
        n_keep = nsample;
    end
    n_keep = max(0, floor(n_keep));

    result.AV = zeros(dis, 1);
    result.cov = zeros(nsample, 1);
    result.cov_all = zeros(nsample, T);
    result.U = nan(nsample, T);
    result.nnuclei = zeros(nsample, 1);
    result.nnucleihist = zeros(priors.npt_max + priors.num_layers, 1);
    result.change_points = zeros( ...
        nsample * (priors.npt_max + priors.num_layers), 1);
    result.CI_density = zeros(dis - 1, dis_y - 1);
    result.vs_all = zeros(n_keep, dis);
    result.forward_model_all = [];
end
