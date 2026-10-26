function EE=ee_adaptive_archive_reset(EE,s)
%EE_ADAPTIVE_ARCHIVE_RESET Remove all transitional pre-reset candidates once.
    if isfinite(EE.archive_reset_at)
        error('EE:RepeatedReset','The E7 archive may be reset only once.');
    end
    EE.archive_reset_discarded=EE.archive_reset_discarded+uint64(EE.archive_count);
    EE.archive_dropped_before_reset=EE.archive_dropped_before_reset+EE.archive_dropped;
    EE.archive_dropped=zeros(EE.nchains,1,'uint64');
    EE.archive=cell(EE.nchains,1);
    EE.archive_count=zeros(EE.nchains,1);
    EE.archive_next_slot=ones(EE.nchains,1);
    EE.archive_slot_ring(:)=uint16(0);
    EE.rings=cell(EE.nchains,EE.nbins);
    EE.ring_count=zeros(EE.nchains,EE.nbins);
    EE.ring_seen=zeros(EE.nchains,EE.nbins,'uint64');
    EE.archive_start=s+1;
    EE.archive_reset_at=s;
    fprintf('EE proposal archive reset at %d; clean refill starts at %d.\n',s,s+1);
end
