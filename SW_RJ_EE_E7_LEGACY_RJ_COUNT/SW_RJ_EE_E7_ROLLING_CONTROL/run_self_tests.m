function run_self_tests
% No Python/disba/MEX required. Does not start a real inversion.
    root=fileparts(mfilename('fullpath')); oldpath=path; oldrng=rng;
    cleanup=onCleanup(@()restore(oldpath,oldrng)); %#ok<NASGU>
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    addpath(fullfile(root,'tests'),'-end');
    fprintf('EE pairwise project self-tests (no real forward model)\n');
    test_dim_truncated; % also runs original DIM/v4 contracts
    test_rj_mixture;
    test_legacy_count_factor;
    test_baseline_rj_regression;
    test_route_a;
    test_ee_pairwise;
    test_ee_configuration;
    test_adaptive_ee;
    test_sequential_ee;
    fprintf('\nAll MATLAB self-tests passed. Run check_true_model_forward next.\n');
    fprintf('These tests do not establish convergence or improved inversion performance.\n');
end
function restore(p,r)
    path(p); rng(r); clear forward_model_misfit
end
