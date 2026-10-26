function test_baseline_rj_regression
% Execute original TUNING Birth/Death/driver alongside current A-disabled code.
% Reference names are unique, so no path swapping of the kernels is needed.
    root=fileparts(mfilename('fullpath')); oldpath=path; oldrng=rng;
    cleanup=onCleanup(@()restore(oldpath,oldrng)); %#ok<NASGU>
    addpath(fullfile(root,'core'),'-begin');
    addpath(fullfile(root,'tests','baseline_reference'),'-begin');
    addpath(fullfile(root,'tests','dim_fixture'),'-begin');
    clear forward_model_misfit
    [a,ra]=trajectory(true); [b,rb]=trajectory(false);
    assert(isequaln(a,b) && isequal(ra,rb));
    fprintf('PASS: A disabled matches original TUNING RJ states, counters and RNG.\n');
end
function [tr,r]=trajectory(original)
    rng(28,'twister');
    p=struct('depth_min',0,'depth_max',10,'npt_min',1,'npt_max',5,'num_layers',1, ...
        'layer_depths',[],'vsmin',300,'vsmax',600,'vp_vs',2, ...
        'rj_state_measure','unordered_iid_uniform_depth');
    x=linspace(0,10,20); p.x=x(:);
    p.vsmin_profile=300*ones(20,1); p.vsmax_profile=600*ones(20,1);
    sig=struct('change_vs',20,'move_depth',1,'birth_vs',100,'birth_mixture',true, ...
        'birth_small',20,'birth_small_weight',.8, ...
        'birth_depth',struct('enabled',false,'local_weight',.5,'halfwidth',2));
    dm=struct('freq',[1;2],'data_mode',[450;450],'dc_num',1,'nd',2,'dim_test_only',true);
    fe=struct('fitting_error',20*ones(2,1));
    T=2; v=zeros(6,T); z=v; n=zeros(1,T); e=n;
    [v,z,n,e,~,~,f]=initialize_chain(1,p,dm,fe,v,z,n,e,T,x);
    num=monitoring(T); beta=[1 .5]; tr=cell(250,1);
    if original, update=@baseline_RJ_C_mian; else, update=@RJ_C_mian; end
    for s=1:250
        for t=1:T
            [z(:,t),v(:,t),f(:,:,t),e(t),n(t),num(t)]=update( ...
                v(:,t),z(:,t),e(t),n(t),p,sig,s,num(t),1,dm,fe,beta(t),x,f(:,:,t));
        end
        tr{s}={z,v,n,e,f,num};
    end
    r=rng;
end
function restore(p,r)
    path(p); rng(r); clear forward_model_misfit
end
