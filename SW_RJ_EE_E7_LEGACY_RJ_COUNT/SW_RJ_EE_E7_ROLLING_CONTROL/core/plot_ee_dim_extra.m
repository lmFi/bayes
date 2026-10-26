function plot_ee_dim_extra(EE)
% Pair-specific plots; no changes to baseline inversion figures.
    if ~EE.enable || isempty(EE.edges), return; end
    C=EE.nchains-1;
    figure('Color','w','Name','EE energy and structure');
    tiledlayout(C,3,'TileSpacing','compact','Padding','compact');
    for r=1:C
        ok=abs(EE.jump_history(:,r))==1;
        accepted=EE.jump_history(:,r)==1;
        nexttile;
        scatter(EE.current_energy(ok,r),EE.candidate_energy(ok,r),8, ...
            double(accepted(ok)), 'filled');
        xlabel('Current energy'); ylabel('Candidate energy');
        title(sprintf('%d <- %d; color 1=accepted',r,r+1)); colorbar;
        nexttile;
        s=find(ok);
        plot(s,EE.profile_rms_delta(ok,r),'.','Color',[.7 .7 .7]); hold on;
        plot(find(accepted),EE.profile_rms_delta(accepted,r),'.');
        xlabel('Iteration'); ylabel('Profile RMS change (m/s)');
        title('Proposed / accepted structure change');
        nexttile;
        histogram(EE.candidate_iteration(accepted,r));
        xlabel('Donor entry iteration'); ylabel('Accepted draws');
        title('Which part of history is reused?');
    end
    figure('Color','w','Name','EE pairwise energy partitions');
    tiledlayout(C,2,'TileSpacing','compact','Padding','compact');
    for r=1:C
        edges=ee_edges_for_chain(EE,r+1); B=numel(edges)-1;
        nexttile;
        plot(EE.energy_history(:,r:r+1)); hold on;
        for b=2:numel(edges)-1, yline(edges(b),'--','Color',[.6 .6 .6]); end
        xlabel('Iteration'); ylabel('Likelihood energy');
        title(sprintf('%d <- %d, %d currently active rings',r,r+1,B));
        legend('Recipient','Donor','Location','best');
        nexttile;
        bar(1:B,EE.ring_count(r+1,1:B));
        xlabel('Ring index within this pair'); ylabel('Donor time entries');
        title('Current FIFO archive, including repeated states');
    end
end
