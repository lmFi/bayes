function test_sequential_ee
% E5/E6/E7 contract: local progress is never replaced by an EE attempt.
% No Python/disba is required.
    root=fileparts(mfilename('fullpath'));
    addpath(fullfile(root,'core'),'-begin');

    E=ee_initialize(12,2,8);
    assert(strcmp(E.update_mode,'local_rj_then_optional_ee'));
    assert(isequal(size(E.energy_before_local),[12 2]));
    E.enable=true; E.nbins=1; E.fixed_edges=[-Inf Inf];
    E.calibration_start=1; E.calibration_end=2; E.jump_start=5;
    E.min_ring_size=1000; % selected EE is deliberately unavailable
    E.jump_probability=.5;
    E=ee_dim_configure(E,12,2,8);
    E.jump_probability=1; % deterministic test branch; production remains <1

    d=[0 0;5 5;0 0]; v=[400 500;600 700;0 0];
    n=[1 1]; like=[20 30]; f=zeros(2,2,2);
    for s=1:12
        E.energy_before_local(s,:)=like;
        E.npt_before_local(s,:)=n;

        % Deterministic stand-in for a completed local RJ kernel. The test
        % checks that an unavailable supplemental EE attempt cannot erase it.
        like=like-[1 .5];
        v(1,:)=v(1,:)+[1 2];
        E.local_updates=E.local_updates+1;
        E.energy_after_local(s,:)=like;
        E.npt_after_local(s,:)=n;
        post_local_like=like; post_local_v=v;

        [d,v,n,like,f,selected,E]=ee_jump(d,v,n,like,f,[1 .5],E,s,1);
        if s<5
            assert(~selected);
        else
            assert(selected && E.jump_history(s,1)==2);
            assert(isequal(like,post_local_like) && isequal(v,post_local_v));
        end
        E.energy_after_ee(s,:)=like;
        E.npt_after_ee(s,:)=n;
        E=ee_ring_update(E,s,d,v,n,like,f);
    end
    assert(all(E.local_updates==12));
    assert(E.jump_triggered(1)==8 && E.jump_unavailable(1)==8);
    assert(all(E.energy_after_ee(:)==E.energy_after_local(:)));

    % Guard the real driver against accidentally reintroducing the old
    % mutually exclusive branch.
    src=fileread(fullfile(root,'Main_rjmcmc_EE.m'));
    assert(~contains(src,'if use_local_rj'));
    assert(contains(src,'EE.energy_before_local(s,:) = like(:).'';'));
    assert(contains(src,'EE.energy_after_local(s,:) = like(:).'';'));
    assert(contains(src,'EE.energy_after_ee(s,:) = like(:).'';'));
    assert(contains(src,'any(EE.local_updates ~= nsample)'));
    fprintf('PASS: mandatory local RJ is preserved before supplemental EE attempts.\n');
end
