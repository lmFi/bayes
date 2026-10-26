function test_route_a
% Run after installing core files in the current inversion project.
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'core'),'-begin');
p=struct('depth_min',0,'depth_max',40);
s=struct('birth_depth',route_a_options);
z=[0;1;20;39;40];
% Integrate piecewise-constant density EXACTLY including clipped/overlap windows.
cuts=unique([0;40;max(0,z-2);min(40,z+2)]); mass=0;
for k=1:numel(cuts)-1
    q=rj_depth_proposal(z,p,s,(cuts(k)+cuts(k+1))/2);
    mass=mass+q*(cuts(k+1)-cuts(k));
end
assert(abs(mass-1)<1e-12);
% Independent expected density: three overlapping windows at z=1.
q=rj_depth_proposal(z,p,s,1);
expected=.5/40+.5/5*(1/2+1/3);
assert(abs(q-expected)<1e-12);
assert(rj_depth_proposal(z,p,s,-1)==0);
% Disabled branch preserves original draw AND following random stream.
s.birth_depth.enabled=false;
rng(42); expectedz=40*rand; nextr=rand;
rng(42); [q,actual]=rj_depth_proposal(z,p,s); actualnext=rand;
assert(actual==expectedz && actualnext==nextr && q==1/40);
s.birth_depth.enabled=true;
% Sampling mass in [0,3] = global contribution + both lower boundary windows.
rng(43); N=20000; hit=0;
for k=1:N
    [q,x]=rj_depth_proposal(z,p,s);
    assert(q>0 && x>=0 && x<=40); hit=hit+(x<=3);
end
assert(abs(hit/N-(.5*3/40+.5*2/5))<.02);
fprintf('PASS: normalized clipped/overlapping windows, density, sampling, disabled RNG.\n');
fprintf('Also run existing RJ tests. These tests do not establish surface-wave performance.\n');
end
