function result_file=Run_recent_history_EE
%RUN_RECENT_HISTORY_EE Compatibility entry; runs E7 continuous FIFO version.
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    cfg=rj_ee_options('five','continuous');
    if ~cfg.ee_adapt_enable || ~cfg.ee_reset_archive_once || ...
            ~strcmp(cfg.ee_archive_mode,'rolling_fifo')
        error('E7:Config','E7 requires adaptive edges, one reset and rolling FIFO history.');
    end
    result_file=Main_rjmcmc_EE(cfg);
end
