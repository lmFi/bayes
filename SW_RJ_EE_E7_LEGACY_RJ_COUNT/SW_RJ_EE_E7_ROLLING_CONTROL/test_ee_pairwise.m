function test_ee_pairwise
% Actual MATLAB EE helpers, no Python/disba. Pair routing and RNG invariants.
    root=fileparts(mfilename('fullpath')); oldpath=path; oldrng=rng;
    cleanup=onCleanup(@()restore(oldpath,oldrng)); %#ok<NASGU>
    addpath(fullfile(root,'core'),'-begin'); rng(50,'twister');
    E=ee_initialize(20,3,8); E.nbins=2; E.calibration_start=1;
    E.calibration_end=4; E.jump_start=7; E.min_ring_size=1;
    E.calibration_mode='pairwise'; E.merge_sparse=false;
    E=ee_dim_configure(E,20,3,8);
    z=repmat([1;4;0],1,3); v=repmat([400;500;0],1,3); n=[1 1 1];
    f=ones(2,2,3);
    for s=1:4
        E=ee_ring_update(E,s,z,v,n,[s s+10 s+40],f);
    end
    assert(~isequal(E.pair_edges{1},E.pair_edges{2}));
    frozen=E.pair_edges;
    for s=5:6, E=ee_ring_update(E,s,z,v,n,[.5 15 25],f); end
    assert(isequal(E.pair_edges,frozen));
    assert(E.ring_count(2,2)==2 && E.ring_count(3,1)==2);
    assert(E.ring_count(3,2)==0);
    assert(isequal([E.rings{3,1}.iteration],[5 6]));
    % Same raw score can fall into different rings for different donor rows.
    assert(ee_dim_bin(25,ee_edges_for_chain(E,2))==2);
    assert(ee_dim_bin(25,ee_edges_for_chain(E,3))==1);
    E.jump_probability=1; % force branch in test only
    [~,~,~,~,~,selected,A]=ee_jump(z,v,n,[15 25 25],f,[1 .5 .25],E,7,2);
    assert(selected && A.jump_history(7,2)==1 && A.selected_ring(7,2)==1);
    assert(A.candidate_energy(7,2)==25 && A.candidate_iteration(7,2)<7);
    fprintf('PASS: different pair edges, donor-specific indexing and frozen full history.\n');

    % Diagnostics must not alter any random draw or accepted model.
    D=E; D.diagnostic_priors=struct('num_layers',1,'depth_min',0,'depth_max',10);
    D.diagnostic_grid=linspace(0,10,51);
    D.rings{3,1}(1).vs=[450;550;0];
    D.rings{3,1}(2).vs=[450;550;0];
    E.rings=D.rings;
    rng(82); [z1,v1,n1,e1,f1,l1,A]=ee_jump(z,v,n,[15 25 25],f,[1 .5 .25],E,7,2); r1=rng;
    rng(82); [z2,v2,n2,e2,f2,l2,B]=ee_jump(z,v,n,[15 25 25],f,[1 .5 .25],D,7,2); r2=rng;
    assert(isequaln({z1,v1,n1,e1,f1,l1,r1},{z2,v2,n2,e2,f2,l2,r2}));
    assert(abs(B.profile_rms_delta(7,2)-50)<1e-12);
    assert(B.profile_max_delta(7,2)==50);
    assert(isnan(A.profile_rms_delta(7,2)));
    fprintf('PASS: profile-distance diagnostics preserve state and RNG.\n');

    % Calibration-time sparse merging, including a genuinely empty donor bin.
    D=E; D.requested_nbins=4; D.merge_sparse=true; D.min_pilot_donor_count=3;
    D.fixed_edges=[]; D.refine_low_energy=false;
    recipient=(1:8).'; donor=(100:107).';
    [edges,report]=ee_calibrate_pair([recipient;donor],recipient,donor,D);
    nr=histcounts(recipient,edges); nd=histcounts(donor,edges);
    assert(all(nd(nr>0)>=3));
    assert(~isempty(report.removed_edges) && edges(1)==-Inf && edges(end)==Inf);
    [tie,~]=ee_calibrate_pair(ones(16,1),ones(8,1),ones(8,1),D);
    assert(all(diff(tie)>0));
    assert(sum(histcounts(ones(8,1),tie))==8);
    D.fixed_edges=[-Inf 50 Inf];
    [fixed,~]=ee_calibrate_pair([recipient;donor],recipient,donor,D);
    assert(isequal(fixed,D.fixed_edges)); % explicit boundaries are never merged
    fprintf('PASS: sparse merging and tied pilots; explicit edges remain fixed.\n');

    % Shared mode must keep the original pooled quantile/refinement formula.
    E=ee_initialize(12,3,8); E.nbins=3; E.calibration_start=1; E.calibration_end=4;
    E.jump_start=7; E.calibration_mode='pooled'; E.refine_low_energy=true;
    E=ee_dim_configure(E,12,3,8); pilot=[];
    for s=1:4
        en=[s s+10 s+40]; pilot=[pilot en]; %#ok<AGROW>
        E=ee_ring_update(E,s,z,v,n,en,f);
    end
    low=linspace(0,median(1:4),7);
    expected=[-Inf unique([quantile(pilot,[1/3 2/3]) low(2:end)]) Inf];
    for t=1:3, assert(isequal(ee_edges_for_chain(E,t),expected)); end
    [sm,ev,cal]=ee_result_tables(E,8);
    assert(height(sm)==2 && height(ev)==0 && height(cal)==2*(numel(expected)-1));
    fprintf('PASS: pooled baseline formula and zero-event tables.\n');

    % Pair-specific ideal donor kernels each preserve the same cold target.
    e=[0 .5 1 2 4]; prior=[.1 .15 .2 .25 .3];
    for edges={[-Inf .7 3 Inf],[-Inf 1.5 Inf]}
        cold=prior.*exp(-e); cold=cold/sum(cold);
        hot=prior.*exp(-.5*e); hot=hot/sum(hot); P=zeros(5);
        b=arrayfun(@(x)ee_dim_bin(x,edges{1}),e);
        for i=1:5
            q=hot.*(b==b(i)); q=q/sum(q);
            for j=1:5
                if i~=j, P(i,j)=q(j)*exp(ee_dim_logaccept(e(i),e(j),1,.5)); end
            end
            P(i,i)=1-sum(P(i,:));
        end
        flow=cold(:).*P;
        assert(max(abs(flow-flow.'),[],'all')<1e-13);
    end
    fprintf('PASS: ideal donor balance with different fixed partitions (not a finite-history proof).\n');
end
function restore(p,r)
    path(p); rng(r);
end
