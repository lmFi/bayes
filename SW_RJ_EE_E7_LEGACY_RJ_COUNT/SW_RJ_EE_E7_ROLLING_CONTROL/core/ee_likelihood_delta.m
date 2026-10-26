function value = ee_likelihood_delta(ex, ey, beta, priors)
% Only the likelihood contribution changes. Prior and RJ proposal terms stay.
    h=-Inf;
    if isfield(priors,'ee_energy_floor'), h=priors.ee_energy_floor; end
    if h==-Inf
        value=beta*(ex-ey); % exact baseline arithmetic, including cold chain
    else
        value=beta*(max(ex,h)-max(ey,h));
    end
end
