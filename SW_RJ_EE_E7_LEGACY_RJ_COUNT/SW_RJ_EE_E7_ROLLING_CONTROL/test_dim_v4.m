function report = test_dim_v4
%TEST_DIM_V4 EE contracts + unchanged actual RJ with EE disabled. No disba.
    root=fileparts(mfilename('fullpath')); oldpath=path; oldrng=rng;
    cleanup=onCleanup(@()restore(oldpath,oldrng)); %#ok<NASGU>
    addpath(fullfile(root,'core'),'-begin');
    addpath(fullfile(root,'tests'),'-end');
    rng(41,'twister');
    test_rj_count_prior_balance; % original v4 test, unchanged
    assert(ee_dim_bin(-100,[-Inf 0 1 Inf])==1);
    assert(ee_dim_bin(0,[-Inf 0 1 Inf])==2);
    assert(ee_dim_bin(1,[-Inf 0 1 Inf])==3);
    assert(ee_dim_bin(1e5,[-Inf 0 1 Inf])==3);
    assert(ee_dim_logaccept(10,5,1,.5)==0);
    assert(ee_dim_logaccept(5,10,1,.5)==-2.5);
    fprintf('PASS: likelihood-only ratio and half-open energy rings.\n');
    prior=[.05 .1 .2 .25 .4]; e=[.2 .8 1.5 1.9 3];
    cold=prior.*exp(-e); cold=cold/sum(cold);
    hot=prior.*exp(-.25*e); hot=hot/sum(hot);
    b=arrayfun(@(v)ee_dim_bin(v,[-Inf 1 2 Inf]),e); P=zeros(5);
    for i=1:5
        q=hot.*(b==b(i)); q=q/sum(q);
        for j=1:5
            if j~=i, P(i,j)=q(j)*exp(ee_dim_logaccept(e(i),e(j),1,.25)); end
        end
        P(i,i)=1-sum(P(i,:));
    end
    flow=bsxfun(@times,cold(:),P); err=max(max(abs(flow-flow.')));
    assert(err<1e-13);
    fprintf('PASS: ideal donor detailed balance, not finite-history convergence (%.3g).\n',err);

    E=ee_initialize(30,2,4); E.calibration_start=1; E.calibration_end=2;
    E.jump_start=5; E.min_ring_size=1; E.nbins=2;
    E.fixed_edges=[-Inf 1 Inf]; E.jump_probability=0;
    E=ee_dim_configure(E,30,2,4);
    z=repmat([1;2;0;0],1,2); v=repmat([400;500;0;0],1,2);
    n=[1 1]; en=[.5 .5]; f=zeros(3,2,2);
    for s=1:20
        for t=1:2
            [~,~,~,~,~,selected,E]=ee_jump(z,v,n,en,f,[1 .5],E,s,t);
            assert(~selected); E.local_updates(t)=E.local_updates(t)+1;
        end
        E=ee_ring_update(E,s,z,v,n,en,f);
    end
    assert(isequal(E.edges,[-Inf 1 Inf]));
    assert(isequal(E.ring_count,[18 0;18 0]));
    assert(isequal(double(E.ring_seen),E.ring_count));
    assert(isequal([E.rings{2,1}.iteration],3:20));
    assert(E.ring_total_history(2,1)==0 && E.ring_total_history(3,1)==1);
    assert(numel(E.rings{2,1})==18); % duplicates were not deduplicated
    fprintf('PASS: frozen boundaries, full sequential history and dwell duplicates.\n');

    E.jump_probability=1; % force branch AFTER valid configuration, test only
    donor=E.rings{2,1}(1); donor.npt=2; donor.depths=[1;3;5;0];
    donor.vs=[450;550;650;0]; donor.forward_model=7*ones(3,2);
    E.rings{2,1}=donor; E.ring_count(2,1)=1;
    [za,va,na,ea,fa,selected,A]=ee_jump(z,v,n,[.8 .5],f,[1 .5],E,21,1);
    assert(selected && A.jump_history(21,1)==1 && A.jump_crossdim_accepted(1)==1);
    assert(isequal(za(:,1),donor.depths) && isequal(va(:,1),donor.vs));
    assert(na(1)==2 && ea(1)==donor.like && isequal(fa(:,:,1),donor.forward_model));
    assert(isequal(za(:,2),z(:,2))); % donor current state unchanged
    assert(A.candidate_iteration(21,1)<21);
    [za,va,na,ea,fa,selected,A]=ee_jump(z,v,n,[2 .5],f,[1 .5],E,21,1);
    assert(selected && A.jump_unavailable(1)==1 && A.jump_history(21,1)==2);
    assert(isequal(za,z) && isequal(va,v) && isequal(na,n) && isequal(ea,[2 .5]) && isequal(fa,f));
    % Reject a very poor candidate in the SAME top ring.
    bad=donor; bad.like=1e6; bad.energy=bad.like;
    E.rings{2,2}=bad; E.ring_count(2,2)=1;
    [za,~,~,ea,~,selected,A]=ee_jump(z,v,n,[2 .5],f,[1 .5],E,21,1);
    assert(selected && A.jump_history(21,1)==-1 && isequal(za,z) && isequal(ea,[2 .5]));
    bad.iteration=21; E.rings{2,2}=bad; caught=false;
    try, ee_jump(z,v,n,[2 .5],f,[1 .5],E,21,1);
    catch ME, caught=strcmp(ME.identifier,'EE:DIMFutureHistory'); end
    assert(caught);
    fprintf('PASS: complete cross-dimensional transfer, self-loops and past-only candidates.\n');

    % Repeated state identity must retain its time weight: 2 of 3 entries.
    D=E; D.rings{2,1}=[donor donor donor];
    D.rings{2,1}(3).vs(1)=900; D.ring_count(2,1)=3;
    hits=0;
    for k=1:2000
        [~,vv,~,~,~,~,~]=ee_jump(z,v,n,[.8 .5],f,[1 .5],D,22,1);
        hits=hits+(vv(1,1)==450);
    end
    assert(abs(hits/2000-2/3)<.06);
    fprintf('PASS: uniform history-entry draws preserve duplicate time weights.\n');

    % Real RJ functions are called in both runs; only forward is a fixture.
    addpath(fullfile(root,'tests','dim_fixture'),'-begin');
    clear forward_model_misfit
    [plain,rand_plain]=actual_rj(false);
    [disabled,rand_disabled]=actual_rj(true);
    assert(isequaln(plain,disabled) && isequal(rand_plain,rand_disabled));
    fprintf('PASS: EE disabled preserves actual v4 RJ trajectory AND random stream.\n');
    report=struct('ideal_balance_error',err,'duplicate_fraction',hits/2000, ...
        'disabled_ee_matches_original_rj',true);
    fprintf('All DIM-EE tests passed. Real disba inversion and performance need separate runs.\n');
end

function [tr,r]=actual_rj(with_ee_wrapper)
    rng(24,'twister');
    p=struct('depth_min',0,'depth_max',10,'npt_min',1,'npt_max',5,'num_layers',1, ...
        'layer_depths',[],'vsmin',300,'vsmax',600,'vp_vs',2, ...
        'rj_state_measure','unordered_iid_uniform_depth');
    x=linspace(0,10,20); p.x=x(:);
    p.vsmin_profile=300*ones(20,1); p.vsmax_profile=600*ones(20,1);
    sig=struct('change_vs',20,'move_depth',1,'birth_vs',100);
    dm=struct('freq',[1;2],'data_mode',[450;450],'dc_num',1,'nd',2,'dim_test_only',true);
    fe=struct('fitting_error',20*ones(2,1));
    T=2; v=zeros(6,T); z=v; n=zeros(1,T); e=n;
    [v,z,n,e,~,~,f]=initialize_chain(1,p,dm,fe,v,z,n,e,T,x);
    num=monitoring(T); beta=[1 .5];
    E=ee_initialize(100,T,50); E.enable=false;
    E=ee_dim_configure(E,100,T,50); tr=cell(100,1);
    for s=1:100
        for t=1:T
            if with_ee_wrapper
                [z,v,n,e,f,selected,E]=ee_jump(z,v,n,e,f,beta,E,s,t); assert(~selected);
            end
            [z(:,t),v(:,t),f(:,:,t),e(t),n(t),num(t)]= ...
                RJ_C_mian(v(:,t),z(:,t),e(t),n(t),p,sig,s,num(t),1,dm,fe,beta(t),x,f(:,:,t));
        end
        if with_ee_wrapper, E=ee_ring_update(E,s,z,v,n,e,f); end
        tr{s}={z,v,n,e,f,num};
    end
    r=rng;
end

function restore(p,r)
    path(p); rng(r);
    clear forward_model_misfit
end
