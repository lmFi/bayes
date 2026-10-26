function result_file=Run_frozen_EE
% Control group: same windows and reset; boundaries freeze before posterior.
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    cfg=rj_ee_options('five','frozen');
    result_file=Main_rjmcmc_EE(cfg);
end
