function EE = ee_ring_update(EE, s, nuclei_depths, nuclei_vs, npt, like, forward_model)
%EE_RING_UPDATE Freeze shared or pairwise rings, then retain all completed states.
% Stored ring entries are time observations, NOT unique models or best models.
    if isfield(EE,'adapt_enable') && EE.adapt_enable && EE.enable
        EE=ee_adaptive_update(EE,s,nuclei_depths,nuclei_vs,npt,like,forward_model);
        return;
    end
    if ~EE.enable && ~EE.truncation_enable, return; end
    if ~EE.configured, error('EE:DIMConfig','Call ee_dim_configure after setting EE options.'); end
    T=size(nuclei_vs,2); energy=like(:).';
    if numel(energy)~=T || any(~isfinite(energy))
        error('EE:DIMCurrentEnergy','Every completed chain state must have finite data misfit.');
    end
    EE.energy_history(s,:)=energy;
    if EE.truncation_enable && s==EE.floor_calibration_end
        pilot=EE.energy_history(EE.floor_calibration_start:s,1);
        if any(~isfinite(pilot)), error('EE:FloorPilot','Missing cold pilot energies.'); end
        EE.energy_floors=[-Inf quantile(pilot,EE.floor_quantiles)];
        EE.floor_frozen_at=s;
        fprintf('Likelihood floors frozen after %d (active next sweep):',s);
        fprintf(' %g',EE.energy_floors); fprintf('\n');
    end
    if ~EE.enable, return; end
    if s>=EE.calibration_start && s<=EE.calibration_end
        EE.energy_buffer=[EE.energy_buffer energy]; %#ok<AGROW>
    end
    if s==EE.calibration_end
        pilots=EE.energy_history(EE.calibration_start:s,:);
        for r=1:T-1
            if strcmp(EE.calibration_mode,'pooled')
                pilot=EE.energy_buffer;
                recipient=pilots(:,1); % legacy low-energy refinement
            else
                pilot=reshape(pilots(:,r:r+1),[],1);
                recipient=pilots(:,r);
            end
            [edges,report]=ee_calibrate_pair(pilot,recipient,pilots(:,r+1),EE);
            % Report recipient occupancy for the actual recipient even in pooled mode.
            report.recipient_count=histcounts(pilots(:,r),edges);
            report.recipient_mass_in_sparse_rings=sum(report.recipient_count( ...
                report.donor_count<EE.min_pilot_donor_count))/size(pilots,1);
            EE.pair_edges{r}=edges;
            EE.pair_nbins(r)=numel(edges)-1;
            EE.calibration_report{r}=report;
            EE.chain_edges{r+1}=edges;
        end
        EE.chain_edges{1}=EE.pair_edges{1};
        EE.edges=EE.pair_edges{1}; % compatibility alias ONLY for the cold pair
        EE.nbins=max(EE.pair_nbins);
        EE.rings=cell(T,EE.nbins);
        EE.ring_count=zeros(T,EE.nbins);
        EE.ring_seen=zeros(T,EE.nbins,'uint64');
        EE.ring_attempts=zeros(max(T-1,1),EE.nbins);
        EE.ring_accepts=zeros(max(T-1,1),EE.nbins);
        EE.boundaries_frozen_at=s;
        EE.archive_start=s+1;
        fprintf('EE boundaries frozen at %d; requested %d rings per pair:\n',s,EE.requested_nbins);
        for r=1:T-1
            fprintf('  %d <- %d: %d rings; edges:',r,r+1,EE.pair_nbins(r));
            fprintf(' %g',EE.pair_edges{r}); fprintf('\n');
        end
    elseif s>EE.calibration_end
        if isempty(EE.edges), error('EE:DIMSchedule','Calibration boundary was skipped.'); end
        if EE.archive_last_iteration~=0 && s~=EE.archive_last_iteration+1
            error('EE:DIMHistoryOrder','Append final states exactly once per completed sweep.');
        end
        if EE.archive_last_iteration==0 && s~=EE.archive_start
            error('EE:DIMArchiveStart','First archive write must follow calibration.');
        end
        for t=1:T
            k=ee_dim_bin(energy(t),ee_edges_for_chain(EE,t));
            state=struct('depths',nuclei_depths(:,t),'vs',nuclei_vs(:,t), ...
                'npt',npt(t),'like',energy(t),'energy',energy(t), ...
                'forward_model',forward_model(:,:,t),'iteration',s);
            if isempty(EE.rings{t,k}), EE.rings{t,k}=state;
            else, EE.rings{t,k}(end+1)=state; end
            EE.ring_count(t,k)=EE.ring_count(t,k)+1;
            EE.ring_seen(t,k)=EE.ring_seen(t,k)+uint64(1);
        end
        EE.archive_last_iteration=s;
    end
    EE.ring_total_history(s,:)=uint32(sum(EE.ring_count,2)).';
    EE.ring_seen_total_history(s,:)=uint32(sum(EE.ring_seen,2)).';
end
