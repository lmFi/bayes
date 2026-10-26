function result_file=Run_rolling_EE
% Continuous group: 4000-energy window, 8000-state FIFO, update to the end.
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    cfg=rj_ee_options('five','continuous');
    result_file=Main_rjmcmc_EE(cfg);
end
