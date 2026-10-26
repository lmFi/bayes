function p=rj_birth_density(value,centre,sigma)
% Full marginal proposal density, not density of selected component.
    widths=sigma.birth_vs; weights=1;
    if isfield(sigma,'birth_mixture') && sigma.birth_mixture
        widths=[sigma.birth_small sigma.birth_vs];
        weights=[sigma.birth_small_weight 1-sigma.birth_small_weight];
    end
    r=(value-centre)./widths;
    p=sum(weights.*exp(-.5*r.^2)./(sqrt(2*pi)*widths));
end
