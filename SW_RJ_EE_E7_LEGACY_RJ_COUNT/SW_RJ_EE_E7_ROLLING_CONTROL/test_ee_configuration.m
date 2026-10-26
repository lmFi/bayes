function test_ee_configuration
% Configuration/data/summaries smoke tests, no disba calls.
    root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'core'),'-begin');
    for name={'five','seven'}
        cfg=resolve_ee_config(rj_ee_options(name{1}));
        assert(strcmp(cfg.run_label,'E7_continuous_4000E_8000S'));
        [data,dm,fe]=load_ee_observations(cfg);
        assert(size(data,2)==4 && isequal(dm.mode_indices,[0 1 2]));
        assert(all(fe.fitting_error(isfinite(dm.data_mode))>=cfg.error_floor));
    end
    cfg=rj_ee_options; cfg.npt_max_typo=7; caught=false;
    try, resolve_ee_config(cfg); catch ME, caught=strcmp(ME.identifier,'Config:Unknown'); end
    assert(caught);
    cfg=rj_ee_options; cfg.Model=[cfg.Model 0]; caught=false;
    try, resolve_ee_config(cfg); catch ME, caught=strcmp(ME.identifier,'true_model_metadata:InvalidModel'); end
    assert(caught);
    for group={'OFF','E0','E1','E2N','E2','E3','E7C','E7F'}
        cfg=resolve_ee_config(ee_experiment_config(group{1},26));
        assert(cfg.seed==26 && cfg.birth_small==20 && cfg.birth_small_weight==.8);
    end
    E=ee_initialize(10,2,4); E.enable=false;
    [summary,events,calibration]=ee_result_tables(E,4);
    assert(summary.Selected(1)==0 && isnan(summary.AcceptedPerValid(1)));
    assert(isempty(events) && isempty(calibration));
    fprintf('PASS: bundled data, config validation, experiment switches and disabled EE output.\n');
end
