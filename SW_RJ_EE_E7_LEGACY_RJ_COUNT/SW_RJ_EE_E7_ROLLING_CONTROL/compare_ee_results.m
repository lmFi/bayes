function comparison=compare_ee_results(files)
% Only compare runs with equal data, prior, noise, iteration budget and PT/floor.
    if ischar(files) || isstring(files), files=cellstr(files); end
    if isempty(files), error('Compare:Empty','Provide result MAT paths.'); end
    comparison=table; reference=[]; reference_data=[];
    same={'case_name','nsample','burn_in','thin','depth_min','depth_max','npt_min','npt_max', ...
        'npt_init','npt_prior','vs_min','vs_max','vp_vs','search_range','min_ratio','max_ratio', ...
        'mode_indices','relative_error','error_floor','birth_mixture','birth_small','birth_large', ...
        'birth_small_weight','change_vs','move_depth','temperatures','enable_pt','swap_interval', ...
        'truncation_enable','floor_quantiles','floor_calibration_start','floor_calibration_end', ...
        'dis','dis_y','Model','ee_calibration_start','ee_calibration_end','ee_jump_start','ee_probability'};
    for j=1:numel(files)
        a=load(files{j},'summary','run_cfg','data');
        if j==1, reference=a.run_cfg; reference_data=a.data; end
        if ~isequaln(a.data,reference_data), error('Compare:Data','Data differ across runs.'); end
        for k=1:numel(same)
            if ~isequaln(a.run_cfg.(same{k}),reference.(same{k}))
                error('Compare:Settings','Cannot attribute differences to EE/A: %s differs.',same{k});
            end
        end
        row=struct2table(a.summary); row.result_file=files(j);
        comparison=[comparison;row]; %#ok<AGROW>
    end
    disp(comparison);
    outdir=fileparts(files{1});
    out=[tempname(outdir) '_comparison.csv']; writetable(comparison,out);
    fprintf('Comparison saved: %s\n',out);
    fprintf('K_half_TV and single-run summaries are diagnostics, not convergence proofs.\n');
end
