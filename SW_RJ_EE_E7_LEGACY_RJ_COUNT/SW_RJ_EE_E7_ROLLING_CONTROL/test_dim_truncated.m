function report=test_dim_truncated
% No Python/disba required. Mathematical and integration contracts.
    root=fileparts(mfilename('fullpath')); oldpath=path; oldrng=rng;
    cleanup=onCleanup(@()restore_env(oldpath,oldrng)); %#ok<NASGU>
    addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
    base=test_dim_v4; % includes actual RJ regression with truncation disabled
    e=[0 .4 1 2 4 8]; prior=[.02 .08 .1 .3 .2 .3];
    br=1; bd=.25; hr=-Inf; hd=2;
    cold=prior.*exp(-br*max(e,hr)); cold=cold/sum(cold);
    hot=prior.*exp(-bd*max(e,hd)); hot=hot/sum(hot);
    bins=arrayfun(@(v)ee_dim_bin(v,[-Inf 1 3 Inf]),e);
    P=zeros(numel(e));
    for i=1:numel(e)
        q=hot.*(bins==bins(i)); q=q/sum(q);
        for j=1:numel(e)
            if i~=j
                P(i,j)=q(j)*exp(ee_dim_logaccept(e(i),e(j),br,bd,hr,hd));
            end
        end
        P(i,i)=1-sum(P(i,:));
    end
    flow=bsxfun(@times,cold(:),P);
    err=max(max(abs(flow-flow.'))); assert(err<1e-13);
    % Symmetric local proposal, nonuniform unheated prior.
    Q=zeros(numel(e)); pri.ee_energy_floor=hd;
    for i=1:numel(e)
        for j=1:numel(e)
            if i~=j
                la=ee_likelihood_delta(e(i),e(j),bd,pri)+log(prior(j)/prior(i));
                Q(i,j)=exp(min(0,la))/numel(e);
            end
        end
        Q(i,i)=1-sum(Q(i,:));
    end
    f=bsxfun(@times,hot(:),Q); localerr=max(max(abs(f-f.')));
    assert(localerr<1e-13);
    pri.ee_energy_floor=-Inf;
    assert(ee_likelihood_delta(2,5,1,pri)==-3);
    pri.ee_energy_floor=4;
    assert(ee_likelihood_delta(2,3,.5,pri)==0);
    assert(ee_likelihood_delta(2,6,.5,pri)==-1);
    assert(ee_likelihood_delta(2,Inf,.5,pri)==-Inf);
    fprintf('PASS: truncated local and ideal EE balance with unequal unheated priors.\n');
    % Pilot, target change, settling, ring pilot, filling, EE start.
    E=ee_initialize(16,2,12); E.truncation_enable=true;
    E.floor_calibration_start=1; E.floor_calibration_end=2; E.floor_quantiles=.5;
    E.calibration_start=5; E.calibration_end=6; E.jump_start=9;
    E.nbins=2; E.refine_low_energy=true; E.min_ring_size=1;
    E=ee_dim_configure(E,16,2,12);
    z=repmat([1;2;0;0],1,2); v=repmat([400;500;0;0],1,2);
    for s=1:10
        E=ee_ring_update(E,s,z,v,[1 1],[s s+2],zeros(3,2,2));
        if s==1, assert(all(E.energy_floors==-Inf)); end
        if s==2, assert(isequal(E.energy_floors,[-Inf 1.5])); end
        if s<=6, assert(sum(E.ring_count(:))==0); end
    end
    assert(E.floor_frozen_at==2 && E.boundaries_frozen_at==6);
    assert(E.archive_start==7 && all(sum(E.ring_count,2)==4));
    assert(isequal(E.energy_floors,[-Inf 1.5]));
    % Force a complete same-ring cross-dimension transfer on a flat hot floor.
    E=ee_initialize(20,2,4); E.calibration_start=1; E.calibration_end=2;
    E.jump_start=5; E.nbins=1; E.fixed_edges=[-Inf Inf]; E.min_ring_size=1;
    E=ee_dim_configure(E,20,2,4); E.energy_floors=[-Inf 4];
    for s=1:4
        E=ee_ring_update(E,s,z,v,[1 2],[2 1],ones(3,2,2));
    end
    E.jump_probability=1; % deterministic branch ONLY in test
    [~,~,n,like,~,selected,E]=ee_jump(z,v,[1 1],[2 2],ones(3,2,2),[1 .5],E,5,1);
    assert(selected && n(1)==2 && like(1)==1 && E.jump_accepted(1)==1);
    fprintf('PASS: freeze/settle/archive timing and complete truncated EE transfer.\n');
    report=struct('baseline',base,'ideal_ee_balance_error',err,'local_balance_error',localerr);
    fprintf('All contract tests passed. Run Main_rjmcmc separately for surface-wave validation.\n');
end
function restore_env(oldpath,oldrng)
    path(oldpath); rng(oldrng);
end
