function test_rj_mixture
    root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'core'),'-begin');
    sigma.birth_vs=100; sigma.birth_small=20;
    sigma.birth_small_weight=.8; sigma.birth_mixture=true;
    mass=integral(@(x)arrayfun(@(v)rj_birth_density(v,500,sigma),x),-Inf,Inf);
    assert(abs(mass-1)<1e-8);
    % Actual prior evaluator on insertion/deletion pair: reciprocal RJ ratios.
    priors.depth_min=0; priors.depth_max=35; priors.npt_min=1; priors.npt_max=7;
    priors.num_layers=1; priors.layer_depths=[];
    priors.rj_state_measure='unordered_iid_uniform_depth';
    priors.vsmin=200; priors.vsmax=1100;
    priors.x=linspace(0,35,150);
    priors.vsmin_profile=200*ones(1,150); priors.vsmax_profile=1100*ones(1,150);
    z=[17.5;5;0;0;0;0;0;0]; v=[700;400;0;0;0;0;0;0];
    for delta=[-100 -20 0 20 100]
        zz=z; vv=v; zz(3)=8; centre=whichnuclei(z(1:2),8,priors);
        vv(3)=v(centre)+delta;
        lp0=logprior_model_state(z,v,1,priors,false);
        lp1=logprior_model_state(zz,vv,2,priors,false);
        reverse_centre=whichnuclei(z(1:2),zz(3),priors);
        gb=rj_birth_density(vv(3),v(centre),sigma);
        gd=rj_birth_density(vv(3),v(reverse_centre),sigma);
        birth=(lp1-lp0)+log((1/3)/2)-log((1/3)/35*gb);
        death=(lp0-lp1)+log((1/3)/35*gd)-log((1/3)/2);
        assert(isfinite(birth) && abs(birth+death)<1e-12);
    end
    sigma.birth_mixture=false;
    expected=exp(-.5*(25/100)^2)/(sqrt(2*pi)*100);
    assert(abs(rj_birth_density(525,500,sigma)-expected)<1e-15);
    fprintf('PASS: normalized mixture, paired RJ prior/proposal ratios, single-width mode.\n');
end
