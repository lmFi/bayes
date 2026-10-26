function [q,z] = rj_depth_proposal(points,priors,sigma,z)
% Draw if z omitted, otherwise evaluate the SAME marginal depth density.
% q = (1-w)/D + w/K * sum_j 1_[a_j,b_j](z)/(b_j-a_j).
% Window overlaps must be summed; windows are clipped BEFORE sampling.
% All active nuclei (including fixed-label nuclei) are proposal anchors.
% This does not change the existing prior or the uniform death selection.
    lo=priors.depth_min; hi=priors.depth_max; D=hi-lo;
    assert(isfinite(D) && D>0,'Invalid depth range.');
    enabled=isfield(sigma,'birth_depth') && sigma.birth_depth.enabled;
    w=0;
    if enabled
        o=sigma.birth_depth;
        validateattributes(o.local_weight,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
        validateattributes(o.halfwidth,{'numeric'},{'scalar','real','finite','positive'});
        w=o.local_weight;
    end
    if w>0
        points=points(:);
        assert(~isempty(points) && all(isfinite(points)) && all(points>=lo & points<=hi), ...
            'Active nuclei must be inside depth bounds.');
        a=max(lo,points-o.halfwidth); b=min(hi,points+o.halfwidth);
    end
    if nargin<4
        if w==0
            z=lo+rand*D; % exact original random draw when disabled
        elseif rand<w
            j=randi(numel(points)); z=a(j)+rand*(b(j)-a(j));
        else
            z=lo+rand*D;
        end
    end
    if ~isfinite(z) || z<lo || z>hi, q=0; return; end
    q=(1-w)/D;
    if w>0
        q=q+w*mean(double(z>=a & z<=b)./(b-a));
    end
end
