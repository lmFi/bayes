function test_legacy_count_factor
% Verify the legacy and unordered RJ birth/death log acceptance differences.
    p=struct('npt_min',1,'npt_max',8,'num_layers',1, ...
        'depth_min',0,'depth_max',10,'x',linspace(0,10,101).');
    p.vsmin_profile=zeros(101,1);
    p.vsmax_profile=ones(101,1);
    p.log_p_npt=repmat(-log(8),1,8);
    capacity=p.num_layers+p.npt_max;
    for n=1:7
        z=zeros(capacity,1); v=zeros(capacity,1);
        z(1:n+1)=linspace(.5,9.5,n+1); v(1:n+1)=.5;
        zb=z; vb=v; zb(n+2)=.25; vb(n+2)=.5;
        p.rj_state_measure='labelled_iid_uniform_depth';
        legacy_now=logprior_model_state(z,v,n,p,false);
        legacy_next=logprior_model_state(zb,vb,n+1,p,false);
        assert(abs(legacy_now-(-log(8)-n*log(10)))<1e-12);
        p.rj_state_measure='unordered_iid_uniform_depth';
        unordered_now=logprior_model_state(z,v,n,p,false);
        unordered_next=logprior_model_state(zb,vb,n+1,p,false);
        birth_delta=(unordered_next-unordered_now)-(legacy_next-legacy_now);
        assert(abs(birth_delta-log(n+1))<1e-12);
        death_delta=(unordered_now-unordered_next)-(legacy_now-legacy_next);
        assert(abs(death_delta+log(n+1))<1e-12);
    end
    fprintf('  PASS: legacy Birth/Death log(n!) switch\n');
end
