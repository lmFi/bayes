function manifest=ee_run_manifest(root,cfg)
% Record the actually resolved code and inputs; catch old project shadowing.
    manifest.created=datestr(now,30);
    manifest.project='SW_RJ_EE_E7_ROLLING_CONTROL';
    manifest.matlab_version=version;
    manifest.config=cfg;
    manifest.target='prior(m)*exp(-beta*max(data_misfit(m),H)); H_cold=-Inf';
    manifest.update_schedule='one local RJ per chain per sweep, then optional supplemental EE';
    manifest.physical_layers='K=npt+1; Voronoi nuclei, boundaries at adjacent midpoints';
    names={'RJ_C_mian','Birth','Death','Move','Change','logprior_model_state', ...
        'thicknesses_and_priors','forward_model_misfit','PhaseDispersion', ...
        'ee_jump','ee_ring_update','ee_adaptive_update', ...
        'ee_adaptive_archive_append','ee_adaptive_reindex','ee_adaptive_archive_reset', ...
        'ee_calibrate_pair','ee_dim_logaccept','ee_likelihood_delta'};
    for j=1:numel(names)
        name=names{j}; expected=fullfile(root,'core',[name '.m']);
        if ~isfile(expected), continue; end
        actual=which(name);
        if ~strcmpi(actual,expected)
            error('Paths:Shadowed','%s resolved to %s; expected %s. Use this project folder and restart after switching projects.',name,actual,expected);
        end
        manifest.code.(name).path=actual;
        manifest.code.(name).source=fileread(actual);
    end
    manifest.data_source=fileread(cfg.data_file);
end
