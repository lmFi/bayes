function Replot_saved_result(result_file)
%REPLOT_SAVED_RESULT Regenerate the v4 figures without rerunning inversion.
%
% Example:
%   Replot_saved_result('Gao_TVF_5_2_result_EE_v3_mixture.mat')
%
% Copy the existing MAT result into this project directory, or provide its
% full path.  The function changes only figures and does not modify the MAT.

    if nargin < 1 || isempty(result_file)
        candidates = { ...
            'Gao_TVF_5_2_result_EE_v4_plotting.mat', ...
            'Gao_TVF_5_2_result_EE_v3_mixture.mat', ...
            'Gao_TVF_5_2_result_1.mat'};
        result_file = '';
        for i = 1:numel(candidates)
            if isfile(candidates{i})
                result_file = candidates{i};
                break;
            end
        end
        if isempty(result_file)
            error('Replot_saved_result:FileNotFound', ...
                ['No default result MAT was found. Call, for example, ' ...
                 'Replot_saved_result(''my_result.mat'').']);
        end
    end

    project_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_dir, 'core'), '-begin');
    saved = load(result_file);

    required = {'result', 'variable', 'priors', 'Model', 'x', ...
        'vs_mode_n0', 'best_model_vs', 'vs_median', 'vs_edge', ...
        'depth_edge', 'CI_density_limitN', 'data_mode', ...
        'forward_model_best', 'burn_in', 'nsample'};
    missing = required(~isfield(saved, required));
    if ~isempty(missing)
        error('Replot_saved_result:MissingVariable', ...
            'The MAT file is missing required variables: %s', ...
            strjoin(missing, ', '));
    end

    vs_mode_plot = Filter_Local_median( ...
        saved.vs_mode_n0, 31, 0.01, 0.05);
    vs_median_plot = Filter_Local_median( ...
        saved.vs_median, 31, 0.01, 0.05);
    vs_mean_plot = Filter_mean5_3(saved.result.AV, 20);

    plot_velocity_posterior(saved.priors, saved.x, saved.Model, ...
        vs_mode_plot, saved.best_model_vs, vs_mean_plot, ...
        vs_median_plot, saved.vs_edge, saved.depth_edge, ...
        saved.CI_density_limitN, saved.result, saved.variable);
    
    plot_dispersion_fit(saved.data_mode, saved.forward_model_best);
    plot_mcmc_diagnostics(saved.result, saved.variable, saved.priors, ...
        saved.Model, saved.burn_in, saved.nsample);

    if isfield(saved, 'EE')
        ee_plot_diagnostics(saved.EE);
        if isfield(saved.EE,'pair_edges'), plot_ee_dim_extra(saved.EE); end
    end
end
