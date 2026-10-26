function [edges, report] = ee_calibrate_pair(pilot, recipient, donor, EE)
%EE_CALIBRATE_PAIR Warm-up only. E is raw likelihood misfit, not posterior.
% Each pair partitions BOTH x and y with the SAME frozen boundaries.
% Sparse merging changes only boundaries; never weights archive entries.
    recipient=recipient(:); donor=donor(:); pilot=pilot(:);
    if isempty(pilot) || any(~isfinite([pilot;recipient;donor]))
        error('EE:Pilot','Pilot energies must be nonempty and finite.');
    end
    if isempty(EE.fixed_edges)
        q=(1:EE.requested_nbins-1)/EE.requested_nbins;
        if isempty(q), inner=[]; else, inner=unique(quantile(pilot,q)); end
        if EE.refine_low_energy
            low=linspace(0,max(median(recipient),eps),7);
            inner=unique([inner(:).' low(2:end)]);
        end
        edges=[-Inf inner(:).' Inf];
    else
        edges=EE.fixed_edges;
    end
    report.initial_edges=edges;
    report.removed_edges=[];
    if EE.merge_sparse && isempty(EE.fixed_edges)
        while numel(edges)>2
            nr=histcounts(recipient,edges); nd=histcounts(donor,edges);
            b=find(nr>0 & nd<EE.min_pilot_donor_count,1,'first');
            if isempty(b), break; end
            B=numel(edges)-1;
            if b==1
                cut=2;
            elseif b==B
                cut=B;
            else
                % Deterministic: merge with the less populated adjacent bin.
                % Counts are time observations, NOT effective sample sizes.
                mass=histcounts(pilot,edges);
                if mass(b-1)<=mass(b+1), cut=b; else, cut=b+1; end
            end
            report.removed_edges(end+1)=edges(cut);
            edges(cut)=[];
        end
    end
    report.edges=edges;
    report.recipient_count=histcounts(recipient,edges);
    report.donor_count=histcounts(donor,edges);
    bad=report.donor_count<EE.min_pilot_donor_count;
    report.recipient_mass_in_sparse_rings= ...
        sum(report.recipient_count(bad))/numel(recipient);
    report.initial_nbins=numel(report.initial_edges)-1;
    report.final_nbins=numel(edges)-1;
end
