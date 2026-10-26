function report=check_true_model_forward(cfg)
% Direct physical-layer forward check. Does not run MCMC or alter observations.
% This checks the forward path, NOT prior support or posterior identifiability.
    root=fileparts(mfilename('fullpath'));
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    if nargin<1, cfg=rj_ee_options; end
    cfg=resolve_ee_config(cfg);
    [observed,dm,fe]=load_ee_observations(cfg);
    initialize_disba; forward_failure_log('reset');
    L=(numel(cfg.Model)+1)/2;
    vs=cfg.Model(1:L); thickness=[cfg.Model(L+1:end) 0];
    vp=cfg.vp_vs*vs; density=.31*vp.^.25;
    [prediction,energy]=forward_model_misfit(thickness,vp,vs,density,dm,fe);
    full_diagnostics=forward_failure_log('get');
    rows=zeros(dm.dc_num,7); single_energy=zeros(1,dm.dc_num);
    for j=1:dm.dc_num
        d=dm; d.data_mode=dm.data_mode(:,j); d.dc_num=1; d.mode_indices=dm.mode_indices(j);
        f=fe; f.fitting_error=fe.fitting_error(:,j);
        [p,e]=forward_model_misfit(thickness,vp,vs,density,d,f);
        mask=isfinite(d.data_mode); matched=mask & isfinite(p(:,2));
        delta=p(matched,2)-d.data_mode(matched);
        rmse=NaN; maxabs=NaN;
        if ~isempty(delta), rmse=sqrt(mean(delta.^2)); maxabs=max(abs(delta)); end
        rows(j,:)=[d.mode_indices sum(mask) sum(matched) sum(mask & ~matched) rmse maxabs e];
        single_energy(j)=e;
    end
    summary=array2table(rows,'VariableNames',{'Mode','Observed','Matched','Missing', ...
        'RMSE_mps','MaxAbs_mps','Energy'});
    disp(summary);
    fprintf('Full energy %.12g; sum of single-mode energies %.12g.\n',energy,sum(single_energy));
    tolerance=.01;
    passed=isfinite(energy) && all(summary.Missing==0) && ...
        all(summary.MaxAbs_mps(summary.Observed>0)<=tolerance);
    if passed
        fprintf('PASS: all observed points reproduced within %.4g m/s.\n',tolerance);
    else
        fprintf('FAIL: inspect model, Vp/Vs, density, mode indices, units and missing roots.\n');
    end
    report=struct('config',cfg,'thickness',thickness,'vs',vs,'vp',vp,'density',density, ...
        'observed',observed,'prediction',prediction,'residual',prediction(:,2:end)-dm.data_mode, ...
        'summary',summary,'full_energy',energy,'full_diagnostics',full_diagnostics, ...
        'check_tolerance_mps',tolerance,'passed',passed);
    if ~isfolder(cfg.output_dir), mkdir(cfg.output_dir); end
    report.result_file=[tempname(cfg.output_dir) '_true_forward.mat'];
    save(report.result_file,'report');
    fprintf('Saved: %s\n',report.result_file);
end
