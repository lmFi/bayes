function test_adaptive_ee
% No Python/disba needed. Verify both E7 policies against exact contracts.
    root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'core'),'-begin');
    continuous=run_policy('continuous');
    frozen=run_policy('frozen');

    assert(isequal([continuous.edge_updates.iteration],[2 4 6 8 10 14:2:30]));
    assert(isequal([frozen.edge_updates.iteration],[2 4 6 8 10]));
    assert(isnan(continuous.boundaries_frozen_at));
    assert(frozen.boundaries_frozen_at==10);

    % Every late continuous epoch uses exactly the most recent four energies.
    u=continuous.edge_updates(end);
    assert(u.pilot_start==27 && u.pilot_end==30);
    % Frozen edges do not move after reset, although its FIFO keeps moving.
    assert(frozen.edge_updates(end).pilot_start==7 && frozen.edge_updates(end).pilot_end==10);

    for item={continuous,frozen}
        E=item{1};
        assert(E.archive_reset_at==10 && E.edge_updates(5).archive_reset);
        assert(all(E.archive_reset_discarded==8));
        assert(all(E.archive_count==8));
        assert(all(E.archive_dropped==12));
        for t=1:2
            assert(isequal(sort([E.archive{t}.iteration]),23:30));
            ids=[E.rings{t,:}]; assert(isequal(sort(ids),1:8));
            for k=1:size(E.rings,2)
                for j=E.rings{t,k}
                    assert(ee_dim_bin(E.archive{t}(j).energy,E.chain_edges{t})==k);
                end
            end
        end
    end
    fprintf(['PASS: rolling 4-energy calibration, rolling 8-state complete FIFO, ', ...
        'continuous/frozen edge policies, one reset, reindexing and past-only draws.\n']);
end

function E=run_policy(policy)
    rng(77); N=30; T=2;
    E=ee_initialize(N,T,20);
    E.enable=true; E.nbins=3; E.min_ring_size=1; E.jump_probability=0.5;
    E.calibration_start=1; E.calibration_end=2; E.jump_start=5;
    E.calibration_mode='pairwise'; E.merge_sparse=false;
    E.refine_low_energy=false; E.truncation_enable=false;
    E.adapt_enable=true; E.adapt_window=4; E.adapt_interval=2;
    E.reset_iteration=10; E.archive_window=8;
    E.adaptation_policy=policy;
    E.update_until_end=strcmp(policy,'continuous');
    E.postreset_calibration='rolling_window';
    E.archive_mode='rolling_fifo'; E.reset_archive_once=true;
    E=ee_dim_configure(E,N,T,20);
    d=[0 0;10 10]; v=[400 500;600 700]; n=[1 1]; f=zeros(2,2,T);
    for s=1:N
        energy=[100+s 110+s]; if s>=5, energy=[s s+1]; end
        if s>=5
            [~,~,~,~,~,~,J]=ee_jump(d,v,n,energy,f,[1 .5],E,s,1);
            if isfinite(J.candidate_iteration(s,1))
                assert(J.candidate_iteration(s,1)<s);
            end
            E=J;
        end
        E=ee_ring_update(E,s,d,v,n,energy,f);
    end
end
