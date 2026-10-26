function files=Run_rolling_vs_frozen(seeds,case_name)
% Controlled comparison. Only the post-reset edge policy differs.
    if nargin<1, seeds=24; end
    if nargin<2, case_name='five'; end
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    policies={'continuous','frozen'};
    files=cell(numel(seeds)*2,1); q=0;
    for seed=seeds(:).'
        for j=1:2
            cfg=rj_ee_options(case_name,policies{j});
            cfg.seed=seed;
            cfg.make_plots=false;
            q=q+1;
            fprintf('\nE7 comparison %d/%d: %s, seed=%d\n', ...
                q,numel(files),policies{j},seed);
            files{q}=Main_rjmcmc_EE(cfg);
        end
    end
    compare_ee_results(files);
end
