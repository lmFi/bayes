function loga = ee_dim_logaccept(ex, ey, br, bd, hr, hd)
% Ideal same-ring donor / PT ratio for p(m)*exp(-beta*max(E,H)).
% Shared unheated priors cancel. Finite empirical history is not an ideal draw.
    if nargin<5, hr=-Inf; end
    if nargin<6, hd=-Inf; end
    if any(~isfinite([ex ey br bd])) || br<=bd || bd<=0 || ...
            isnan(hr) || isnan(hd) || hr==Inf || hd==Inf
        error('EE:DIMRatio','Invalid energies, inverse temperatures or floors.');
    end
    if hr==-Inf && hd==-Inf
        loga=min(0,(br-bd)*(ex-ey));
    else
        loga=min(0,br*(max(ex,hr)-max(ey,hr)) + ...
            bd*(max(ey,hd)-max(ex,hd)));
    end
end
