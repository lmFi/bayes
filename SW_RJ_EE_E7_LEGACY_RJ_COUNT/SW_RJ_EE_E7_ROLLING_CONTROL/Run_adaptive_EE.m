function result_file=Run_adaptive_EE
% Compatibility entry. E7 runs local RJ first and optional EE second.
    root=fileparts(mfilename('fullpath')); addpath(root,'-begin');
    addpath(fullfile(root,'core'),'-begin');
    cfg=rj_ee_options('five','continuous');
    result_file=Main_rjmcmc_EE(cfg);
end
