function [rms_delta,max_delta] = ee_profile_distance(zx,vx,nx,zy,vy,ny,priors,grid)
% Equal-depth-grid Vs distance. Diagnostic only; no random draws or weights.
    if isempty(priors) || isempty(grid)
        rms_delta=NaN; max_delta=NaN; return;
    end
    a=profile(zx,vx,nx,priors,grid);
    b=profile(zy,vy,ny,priors,grid);
    rms_delta=sqrt(mean((a-b).^2));
    max_delta=max(abs(a-b));
end

function v=profile(z,vs,n,priors,grid)
    K=n+priors.num_layers; z=z(1:K); vs=vs(1:K);
    if priors.num_layers==1
        % Same active-point restriction and first-tie rule as whichnuclei.
        ids=find(z>=priors.depth_min & z<priors.depth_max);
        if isempty(ids), ids=(1:K).'; end
        [~,idx]=min(abs(z(ids)-grid(:).'),[],1);
        v=reshape(vs(ids(idx)),1,[]);
    else
        v=zeros(1,numel(grid));
        for k=1:numel(grid), v(k)=vs(whichnuclei(z,grid(k),priors)); end
    end
end
