function EE=ee_adaptive_archive_append(EE,t,state)
%EE_ADAPTIVE_ARCHIVE_APPEND Add one completed state.
% E7 keeps exactly the most recent archive_window complete states per chain.
% The archive is a circular buffer with stable slot numbers.  EE.rings stores
% those slot numbers, so overwriting one state does not renumber the others.
    cap=EE.archive_window;
    count=EE.archive_count(t);
    slot=EE.archive_next_slot(t);

    if count==cap
        old_ring=double(EE.archive_slot_ring(t,slot));
        if old_ring<1
            error('EE:ArchiveIndex','Occupied FIFO slot has no ring index.');
        end
        ids=EE.rings{t,old_ring};
        pos=find(ids==slot,1,'first');
        if isempty(pos)
            error('EE:ArchiveIndex','FIFO slot is missing from its old ring.');
        end
        ids(pos)=[];
        EE.rings{t,old_ring}=ids;
        EE.ring_count(t,old_ring)=EE.ring_count(t,old_ring)-1;
        EE.archive_dropped(t)=EE.archive_dropped(t)+uint64(1);
    else
        count=count+1;
        EE.archive_count(t)=count;
    end

    if isempty(EE.archive{t})
        EE.archive{t}=state;
    elseif slot<=numel(EE.archive{t})
        EE.archive{t}(slot)=state;
    else
        % Before the buffer first fills, slots are created sequentially.
        if slot~=numel(EE.archive{t})+1
            error('EE:ArchiveSlot','Non-sequential FIFO slot creation.');
        end
        EE.archive{t}(slot)=state;
    end

    k=ee_dim_bin(state.energy,EE.chain_edges{t});
    EE.archive_slot_ring(t,slot)=uint16(k);
    EE.rings{t,k}(end+1)=slot;
    EE.ring_count(t,k)=EE.ring_count(t,k)+1;
    EE.ring_seen(t,k)=EE.ring_seen(t,k)+uint64(1);
    EE.archive_seen(t)=EE.archive_seen(t)+uint64(1);
    EE.archive_next_slot(t)=mod(slot,cap)+1;
end
