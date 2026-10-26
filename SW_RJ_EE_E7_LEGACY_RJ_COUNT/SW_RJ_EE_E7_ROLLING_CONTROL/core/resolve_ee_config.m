function cfg=resolve_ee_config(cfg)
% Fill missing fields; reject misspelled fields rather than silently ignore.
    if nargin<1 || isempty(cfg), cfg=rj_ee_options; end
    if ~isstruct(cfg) || ~isscalar(cfg), error('Config:Type','cfg must be a scalar struct.'); end
    if isfield(cfg,'case_name'), base=rj_ee_options(cfg.case_name); else, base=rj_ee_options; end
    names=fieldnames(base); unknown=setdiff(fieldnames(cfg),names);
    if ~isempty(unknown), error('Config:Unknown','Unknown config fields: %s',strjoin(unknown,', ')); end
    for k=1:numel(names)
        if ~isfield(cfg,names{k}), cfg.(names{k})=base.(names{k}); end
    end
    ints={'nsample','thin','npt_min','npt_max','npt_init','dis','dis_y','show','swap_interval'};
    for k=1:numel(ints)
        validateattributes(cfg.(ints{k}),{'numeric'},{'scalar','integer','positive','finite'},'',ints{k});
    end
    validateattributes(cfg.burn_in,{'numeric'},{'scalar','integer','nonnegative','<',cfg.nsample});
    validateattributes(cfg.seed,{'numeric'},{'scalar','integer','nonnegative','<=',2^32-1});
    if floor(cfg.nsample/cfg.thin)<=floor(cfg.burn_in/cfg.thin)
        error('Config:Samples','No retained posterior samples.');
    end
    if cfg.npt_min>cfg.npt_init || cfg.npt_init>cfg.npt_max
        error('Config:Counts','Require npt_min <= npt_init <= npt_max.');
    end
    cfg.rj_state_measure=char(cfg.rj_state_measure);
    if ~any(strcmp(cfg.rj_state_measure, ...
            {'labelled_iid_uniform_depth','unordered_iid_uniform_depth'}))
        error('Config:StateMeasure','Unknown rj_state_measure.');
    end
    validateattributes(cfg.depth_min,{'numeric'},{'scalar','real','finite','nonnegative'});
    if cfg.depth_min~=0, error('Config:Depth','This baseline parameterization starts at depth 0.'); end
    validateattributes(cfg.depth_max,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(cfg.vs_min,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(cfg.vs_max,{'numeric'},{'scalar','real','finite','>',cfg.vs_min});
    positives={'vp_vs','error_floor','birth_small','birth_large','change_vs','move_depth','a_halfwidth','min_ratio','max_ratio'};
    for k=1:numel(positives)
        validateattributes(cfg.(positives{k}),{'numeric'},{'scalar','real','positive','finite'},'',positives{k});
    end
    validateattributes(cfg.relative_error,{'numeric'},{'scalar','real','finite','nonnegative'});
    validateattributes(cfg.birth_small_weight,{'numeric'},{'scalar','real','finite','>=',0,'<=',1});
    validateattributes(cfg.a_local_weight,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
    validateattributes(cfg.temperatures,{'numeric'},{'vector','real','finite','positive'});
    cfg.temperatures=cfg.temperatures(:).';
    if numel(cfg.temperatures)<1 || cfg.temperatures(1)~=1 || any(diff(cfg.temperatures)<=0)
        error('Config:Temperatures','Use increasing temperatures starting at 1.');
    end
    if cfg.dis<32 || cfg.dis_y<4, error('Config:Grid','Use dis>=32 and dis_y>=4 for baseline plots.'); end
    if ~any(strcmp(cfg.search_range,{'fixed','increasing'}))
        error('Config:Bounds','search_range must be fixed or increasing.');
    end
    bools={'enable_ee','enable_pt','enable_a','birth_mixture','ee_merge_sparse', ...
        'ee_refine_low_energy','ee_adapt_enable', ...
        'ee_reset_archive_once','ee_update_until_end', ...
        'truncation_enable','make_plots','save_history','save_csv'};
    for k=1:numel(bools)
        v=cfg.(bools{k});
        if ~isscalar(v) || ~(islogical(v) || isnumeric(v)) || ~ismember(v,[0 1])
            error('Config:Boolean','%s must be true or false.',bools{k});
        end
    end
    validateattributes(cfg.ee_reset_iteration,{'numeric'}, ...
        {'scalar','integer','positive','finite'},'','ee_reset_iteration');
    validateattributes(cfg.ee_archive_window,{'numeric'}, ...
        {'scalar','integer','positive','finite'},'','ee_archive_window');
    if ~any(strcmp(cfg.ee_adaptation_policy,{'continuous','frozen'}))
        error('Config:AdaptationPolicy', ...
            'ee_adaptation_policy must be ''continuous'' or ''frozen''.');
    end
    if ~strcmp(cfg.ee_archive_mode,'rolling_fifo')
        error('Config:ArchiveMode','E7 requires ee_archive_mode=''rolling_fifo''.');
    end
    if ~strcmp(cfg.ee_postreset_calibration,'rolling_window')
        error('Config:PostresetPilot', ...
            'E7 requires ee_postreset_calibration=''rolling_window''.');
    end
    expected_update=strcmp(cfg.ee_adaptation_policy,'continuous');
    if logical(cfg.ee_update_until_end)~=expected_update
        error('Config:AdaptationPolicy', ...
            'update_until_end must be true for continuous and false for frozen.');
    end
    if ~isempty(cfg.npt_prior)
        w=cfg.npt_prior(:).';
        if numel(w)~=cfg.npt_max-cfg.npt_min+1 || any(~isfinite(w) | w<=0)
            error('Config:CountPrior','npt_prior needs one positive weight per allowed npt.');
        end
        cfg.npt_prior=w/sum(w);
    end
    cfg.data_file=char(cfg.data_file);
    if ~isfile(cfg.data_file), error('Config:DataFile','File does not exist: %s',cfg.data_file); end
    [ok,attrs]=fileattrib(cfg.data_file);
    if ok, cfg.data_file=attrs.Name; end
    cfg.Model=cfg.Model(:).';
    [L,~]=true_model_metadata(cfg.Model); % reject extra half-space zero before sampling
    if isempty(cfg.Model) || any(~isfinite(cfg.Model)) || ...
            any(cfg.Model(1:L)<=0) || any(cfg.Model(L+1:end)<=0)
        error('Config:Reference','Model needs positive Vs and positive finite-layer thicknesses; omit half-space zero.');
    end
    if isempty(cfg.output_dir), error('Config:Output','output_dir cannot be empty.'); end
    cfg.run_label=regexprep(char(cfg.run_label),'[^a-zA-Z0-9_-]','_');
end
