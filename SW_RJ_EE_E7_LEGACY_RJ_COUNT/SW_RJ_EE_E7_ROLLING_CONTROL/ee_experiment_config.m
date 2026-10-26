function cfg=ee_experiment_config(group,seed,case_name)
% Controlled ablations. RJ prior, data, error and run budget remain identical.
    if nargin<2, seed=26; end
    if nargin<3, case_name='five'; end
    cfg=rj_ee_options(case_name); cfg.seed=seed;
    cfg.enable_a=false; cfg.enable_pt=false; cfg.truncation_enable=false;
    cfg.ee_merge_sparse=false; cfg.ee_refine_low_energy=false;
    group=upper(char(group));
    switch group
        case 'OFF'
            cfg.enable_ee=false;
        case 'E0'
            cfg.ee_calibration_mode='pooled';
            cfg.ee_refine_low_energy=true; % original TUNING ring construction
        case 'E1'
            cfg.ee_calibration_mode='pooled';
        case 'E2N'
            cfg.ee_calibration_mode='pairwise'; % isolate pairwise construction
        case 'E2'
            cfg.ee_calibration_mode='pairwise';
            cfg.ee_merge_sparse=true;
        case 'E3'
            cfg.ee_calibration_mode='pairwise'; cfg.ee_merge_sparse=true;
            cfg.enable_a=true;
        case 'E7C'
            cfg=rj_ee_options(case_name,'continuous'); cfg.seed=seed;
        case 'E7F'
            cfg=rj_ee_options(case_name,'frozen'); cfg.seed=seed;
        otherwise
            error('Experiments:Group','Use OFF, E0, E1, E2N, E2, E3, E7C or E7F.');
    end
    cfg.run_label=group;
end
