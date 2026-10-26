function EE=ee_adaptive_reindex(EE)
%EE_ADAPTIVE_REINDEX Rebuild ring indexes for every active archive entry.
% No state is copied, re-evaluated or deduplicated.
    T=EE.nchains;
    EE.rings=cell(T,EE.nbins);
    EE.ring_count=zeros(T,EE.nbins);
    EE.ring_seen=zeros(T,EE.nbins,'uint64');
    EE.archive_slot_ring(:)=uint16(0);
    for t=1:T
        count=EE.archive_count(t);
        if count==0, continue; end
        slots=1:count; % before full: 1:count; when full: 1:capacity
        if numel(EE.archive{t})~=count
            error('EE:ArchiveCount','Active archive slots and archive_count disagree.');
        end
        values=[EE.archive{t}(slots).energy];
        [~,~,bins]=histcounts(values,EE.chain_edges{t});
        if any(bins<1)
            error('EE:ArchiveEnergy','An active energy was not assigned to a ring.');
        end
        EE.archive_slot_ring(t,slots)=uint16(bins);
        for k=1:numel(EE.chain_edges{t})-1
            ids=slots(bins==k);
            EE.rings{t,k}=ids;
            EE.ring_count(t,k)=numel(ids);
            EE.ring_seen(t,k)=uint64(numel(ids));
        end
        if sum(EE.ring_count(t,:))~=count
            error('EE:ArchiveConservation','Reindexing lost an active archive entry.');
        end
    end
end
