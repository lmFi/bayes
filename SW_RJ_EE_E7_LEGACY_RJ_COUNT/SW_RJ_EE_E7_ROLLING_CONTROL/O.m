clear ; close all
cfg = rj_ee_options('five','continuous');
cfg.enable_ee = false;
cfg.enable_pt = true;
cfg.birth_mixture = false;
file = Main_rjmcmc_EE(cfg);