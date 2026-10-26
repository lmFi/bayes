function EE=ee_adaptive_update(EE,s,depths,vs,npt,like,fwd)
% End-of-sweep only.
% Boundaries always use the most recent adapt_window completed energies.
% At reset: keep the newly calibrated edges but discard all old candidates.
% Thereafter the complete-state proposal archive is a strict FIFO.  With the
% continuous policy edges keep updating; with frozen they stop at reset.
% New edges become active on the following sweep.
    if ~EE.configured, error('EE:Config','Configure EE first.'); end
    if s~=EE.adaptive_last_sweep+1
        error('EE:Order','Call once per completed sweep, starting at 1.');
    end
    EE.adaptive_last_sweep=s;
    energy=like(:).'; T=size(vs,2);
    if numel(energy)~=T || any(~isfinite(energy))
        error('EE:Energy','All completed states must have finite energy.');
    end
    if s>1 && any(~isfinite(EE.energy_history(s-1,:)))
        error('EE:Order','Missing preceding sweep.');
    end
    EE.energy_history(s,:)=energy;
    first=s==EE.calibration_end;
    pre_reset_update=s>EE.calibration_end && s<=EE.reset_iteration && ...
        (mod(s,EE.adapt_interval)==0 || s==EE.reset_iteration);
    % Do not mix pre-reset energy into a post-reset boundary.  Wait until a
    % complete clean adapt_window is available, then update at the interval.
    post_ready=EE.reset_iteration+EE.adapt_window;
    post_reset_update=EE.update_until_end && s>=post_ready && ...
        mod(s-post_ready,EE.adapt_interval)==0;
    update=first || pre_reset_update || post_reset_update;
    % This sweep's state is appended ONCE, before reindexing, never proposed
    % until the next sweep. Initial calibration states are NOT archived.
    if s>EE.calibration_end
        if s~=EE.calibration_end+1 && s~=EE.archive_last_iteration+1
            error('EE:ArchiveOrder','Archive exactly once in sequential order.');
        end
        for t=1:T
            state=struct('depths',depths(:,t),'vs',vs(:,t),'npt',npt(t), ...
                'like',energy(t),'energy',energy(t),'forward_model',fwd(:,:,t),'iteration',s);
            EE=ee_adaptive_archive_append(EE,t,state);
        end
        EE.archive_last_iteration=s;
    end
    if update
        start=max(EE.calibration_start,s-EE.adapt_window+1);
        if s<EE.reset_iteration
            phase='rolling_pre_reset';
        elseif s==EE.reset_iteration
            if strcmp(EE.adaptation_policy,'frozen')
                phase='final_frozen';
            else
                phase='reset_boundary';
            end
        else
            phase='rolling_post_reset';
        end
        pilots=EE.energy_history(start:s,:);
        if any(~isfinite(pilots(:)))
            error('EE:PilotHistory','Adaptive pilot contains a missing or nonfinite energy.');
        end
        reports=cell(1,T-1);
        for r=1:T-1
            pooled=reshape(pilots(:,r:r+1),[],1);
            [edges,reports{r}]=ee_calibrate_pair(pooled,pilots(:,r),pilots(:,r+1),EE);
            EE.pair_edges{r}=edges;
            EE.pair_nbins(r)=numel(edges)-1;
            EE.chain_edges{r+1}=edges;
        end
        EE.chain_edges{1}=EE.pair_edges{1};
        EE.edges=EE.pair_edges{1}; EE.nbins=max(EE.pair_nbins);
        EE.calibration_report=reports;
        EE=ee_adaptive_reindex(EE);
        % Ring numbers change meaning at each epoch. Preserve old per-ring
        % counters in the epoch record; lifetime jump counters never reset.
        if EE.edge_epoch>0
            EE.edge_updates(end).attempts=EE.ring_attempts;
            EE.edge_updates(end).accepts=EE.ring_accepts;
        end
        EE.ring_attempts=zeros(T-1,EE.nbins);
        EE.ring_accepts=zeros(T-1,EE.nbins);
        counts_before_reset=EE.ring_count;
        reset_now=(s==EE.reset_iteration && EE.reset_archive_once);
        if reset_now
            EE=ee_adaptive_archive_reset(EE,s);
        end
        EE.edge_epoch=EE.edge_epoch+1;
        entry=struct('iteration',s,'active_from',s+1,'pilot_start',start, ...
            'pilot_end',s,'edges',{EE.pair_edges},'report',{reports}, ...
            'archive_counts_before_reset',counts_before_reset, ...
            'archive_counts',EE.ring_count,'archive_reset',reset_now, ...
            'archive_window',EE.archive_window,'phase',phase, ...
            'attempts',[],'accepts',[]);
        EE.edge_updates(EE.edge_epoch)=entry;
        if isnan(EE.archive_start), EE.archive_start=EE.calibration_end+1; end
        if reset_now && strcmp(EE.adaptation_policy,'frozen')
            EE.boundaries_frozen_at=s;
        elseif reset_now
            EE.boundaries_frozen_at=NaN;
        end
        fprintf('EE edge epoch %d at %d, pilot %d:%d, phase=%s, reset=%d\n', ...
            EE.edge_epoch,s,start,s,phase,reset_now);
        for r=1:T-1
            fprintf('  %d <- %d:',r,r+1); fprintf(' %g',EE.pair_edges{r}); fprintf('\n');
        end
    end
    % Row s records the epoch ACTIVE DURING sweep s, not its end update.
    EE.edge_epoch_history(s)=uint32(EE.edge_epoch-double(update));
    EE.ring_total_history(s,:)=uint32(EE.archive_count(:).');
    EE.ring_seen_total_history(s,:)=uint32(sum(EE.ring_seen,2)).';
    if s==EE.nsample && EE.edge_epoch>0
        EE.edge_updates(end).attempts=EE.ring_attempts;
        EE.edge_updates(end).accepts=EE.ring_accepts;
    end
end
