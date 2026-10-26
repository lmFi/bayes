function files=run_ee_comparison(seeds,groups,case_name)
% Defaults to continuous/frozen E7 runs for each held-out seed 26 and 27.
% E7 comparison: run_ee_comparison([24 26],{'E7C','E7F'},'five')
    if nargin<1, seeds=[26 27]; end
    if nargin<2, groups={'E7C','E7F'}; end
    if nargin<3, case_name='five'; end
    if ischar(groups) || isstring(groups), groups=cellstr(groups); end
    files=cell(numel(seeds)*numel(groups),1); index=0;
    for seed=seeds(:).'
        for j=1:numel(groups)
            cfg=ee_experiment_config(groups{j},seed,case_name);
            cfg.make_plots=false;
            index=index+1;
            fprintf('\nComparison %d/%d: %s seed %d\n',index,numel(files),groups{j},seed);
            files{index}=Main_rjmcmc_EE(cfg);
        end
    end
    compare_ee_results(files);
end
