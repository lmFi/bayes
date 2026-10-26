function EE = ee_dim_configure(EE, nsample, T, burn_in)
%EE_DIM_CONFIGURE Validate EE only; never change RJ or posterior settings.
    validateattributes(EE.jump_probability,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
    validateattributes(EE.jump_interval,{'numeric'},{'scalar','integer','positive'});
    validateattributes(EE.nbins,{'numeric'},{'scalar','integer','positive'});
    validateattributes(EE.min_ring_size,{'numeric'},{'scalar','integer','positive'});
    if EE.enable
        stages=[EE.calibration_start EE.calibration_end EE.jump_start];
        if any(~isfinite(stages)) || any(stages~=floor(stages)) || ...
                stages(1)<1 || stages(2)<stages(1) || stages(3)<=stages(2)+1 || ...
                stages(3)>nsample
            error('EE:DIMStages','Require 1 <= calibration_start <= calibration_end < jump_start-1 <= nsample-1.');
        end
        if burn_in < EE.jump_start-1
            error('EE:DIMCollection','EE starts after posterior collection: adjust EE stage settings, not RJ.');
        end
        if T<2, error('EE:DIMChains','EE needs at least two temperature chains.'); end
        if EE.ring_thin~=1 || ~isinf(EE.max_per_ring)
            error('EE:DIMHistory','Runtime EE archiving requires ring_thin=1 and the compatibility max_per_ring=Inf.');
        end
    end
    if ~isempty(EE.fixed_edges)
        e=EE.fixed_edges(:).';
        if numel(e)<2 || e(1)~=-Inf || e(end)~=Inf || any(isnan(e)) || any(diff(e)<=0)
            error('EE:DIMEdges','fixed_edges must be strictly increasing [-Inf ... Inf].');
        end
        EE.fixed_edges=e;
    end
    if ~any(strcmp(EE.calibration_mode,{'pooled','pairwise'}))
        error('EE:CalibrationMode','Use pooled or pairwise.');
    end
    validateattributes(EE.min_pilot_donor_count,{'numeric'},{'scalar','integer','positive'});
    if EE.merge_sparse && strcmp(EE.calibration_mode,'pooled')
        error('EE:MergeMode','Sparse merging is pairwise only; pooled is the exact baseline option.');
    end
    EE.requested_nbins=EE.nbins;
    EE.nsample=nsample; EE.nchains=T;
    if EE.truncation_enable
        if EE.floor_calibration_start<1 || ...
                EE.floor_calibration_start>EE.floor_calibration_end || ...
                EE.floor_calibration_end>=EE.calibration_start || ...
                numel(EE.floor_quantiles)~=T-1 || ...
                any(EE.floor_quantiles<=0 | EE.floor_quantiles>=1) || ...
                any(diff(EE.floor_quantiles)<0)
            error('EE:FloorSchedule','Require ordered floor pilot before ring calibration, and T-1 ordered quantiles in (0,1).');
        end
    end
    if ~isfield(EE,'adapt_enable'), EE.adapt_enable=false; end
    if EE.adapt_enable && EE.enable
        validateattributes(EE.adapt_enable,{'logical','numeric'},{'scalar','binary'});
        validateattributes(EE.adapt_window,{'numeric'},{'scalar','integer','positive','finite'});
        validateattributes(EE.adapt_interval,{'numeric'},{'scalar','integer','positive','finite'});
        validateattributes(EE.reset_iteration,{'numeric'}, ...
            {'scalar','integer','finite','>',EE.calibration_end,'<',nsample});
        validateattributes(EE.archive_window,{'numeric'}, ...
            {'scalar','integer','positive','finite'});
        validateattributes(EE.update_until_end,{'logical','numeric'},{'scalar','binary'});
        validateattributes(EE.reset_archive_once,{'logical','numeric'},{'scalar','binary'});
        if ~strcmp(EE.calibration_mode,'pairwise') || ~isempty(EE.fixed_edges) || EE.truncation_enable
            error('EE:AdaptiveMode','Adaptive version requires pairwise, empty fixed_edges and no truncation.');
        end
        if EE.reset_iteration < EE.jump_start
            error('EE:AdaptiveSchedule','The one-time archive reset must follow the first EE jump.');
        end
        if EE.archive_window<EE.min_ring_size
            error('EE:ArchiveCapacity','archive_window must be >= min_ring_size.');
        end
        if ~any(strcmp(EE.adaptation_policy,{'continuous','frozen'})) || ...
                ~strcmp(EE.archive_mode,'rolling_fifo') || ...
                ~strcmp(EE.postreset_calibration,'rolling_window') || ...
                ~EE.reset_archive_once
            error('EE:E7Mode', ...
                ['E7 requires one reset, rolling-window calibration and ', ...
                 'a rolling complete-state FIFO archive.']);
        end
        if logical(EE.update_until_end)~=strcmp(EE.adaptation_policy,'continuous')
            error('EE:E7Policy','Continuous must update to end; frozen must stop at reset.');
        end
        EE.adaptive_last_sweep=0;
        EE.archive=cell(T,1);
        EE.archive_count=zeros(T,1);
        EE.archive_next_slot=ones(T,1);
        EE.archive_slot_ring=zeros(T,EE.archive_window,'uint16');
        EE.archive_seen=zeros(T,1,'uint64');
        EE.archive_dropped=zeros(T,1,'uint64');
        EE.archive_dropped_before_reset=zeros(T,1,'uint64');
        EE.archive_reset_discarded=zeros(T,1,'uint64');
        EE.archive_reset_at=NaN;
        EE.edge_epoch=0;
        EE.edge_epoch_history=zeros(nsample,1,'uint32');
        % MATLAB does not permit assigning a populated struct into a
        % fieldless struct([]).  Predeclare the exact epoch-record schema.
        EE.edge_updates=struct('iteration',{},'active_from',{}, ...
            'pilot_start',{},'pilot_end',{},'edges',{},'report',{}, ...
            'archive_counts_before_reset',{},'archive_counts',{}, ...
            'archive_reset',{},'archive_window',{},'phase',{}, ...
            'attempts',{},'accepts',{});
        EE.storage_mode='recent_complete_state_fifo';
        fprintf(['EE adaptation: recent %d energies, update every %d sweeps; ', ...
            'one archive reset at %d; policy=%s.\n'], ...
            EE.adapt_window,EE.adapt_interval,EE.reset_iteration,EE.adaptation_policy);
        if EE.update_until_end
            fprintf('First clean post-reset edge update: %d.\n', ...
                EE.reset_iteration+EE.adapt_window);
        else
            fprintf('Edges freeze at reset iteration %d, before posterior collection.\n', ...
                EE.reset_iteration);
        end
        fprintf('EE proposal archive: recent %d complete states/chain (strict FIFO).\n', ...
            EE.archive_window);
    end
    EE.configured=true;
    if EE.enable
        fprintf('EE update schedule: one mandatory local RJ per chain, then optional supplemental EE.\n');
        if EE.adapt_enable
            history_text=sprintf('recent %d-state FIFO',EE.archive_window);
        else
            history_text='full post-calibration history';
        end
        fprintf('EE: %s pilot; likelihood energy; %s; merge=%d; floor=%d.\n', ...
            EE.calibration_mode,history_text,EE.merge_sparse,EE.truncation_enable);
        fprintf('EE calibration %d:%d; filling %d:%d; jumps from %d; posterior burn-in stays %d.\n', ...
            EE.calibration_start,EE.calibration_end,EE.calibration_end+1,EE.jump_start-1,EE.jump_start,burn_in);
    end
end
