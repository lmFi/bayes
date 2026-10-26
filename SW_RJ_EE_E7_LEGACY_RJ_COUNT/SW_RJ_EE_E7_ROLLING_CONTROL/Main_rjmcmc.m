function result_file=Main_rjmcmc(cfg)
% Compatibility entry; configuration controls all settings and iteration count.
    if nargin<1, cfg=rj_ee_options; end
    result_file=Main_rjmcmc_EE(cfg);
end
