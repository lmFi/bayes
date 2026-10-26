function result_file=Run_sequential_EE
%RUN_SEQUENTIAL_EE Default E7 continuous rolling-window experiment.
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    cfg=rj_ee_options('five','continuous');
    if ~cfg.enable_ee || ~cfg.ee_adapt_enable || ...
            ~cfg.ee_reset_archive_once || ~cfg.ee_update_until_end || ...
            ~strcmp(cfg.ee_archive_mode,'rolling_fifo')
        error('E7:Config', ...
            ['E7 continuous requires adaptive pairwise edges, one reset, ', ...
             'rolling energy calibration and a complete-state FIFO.']);
    end
    result_file=Main_rjmcmc_EE(cfg);
end
