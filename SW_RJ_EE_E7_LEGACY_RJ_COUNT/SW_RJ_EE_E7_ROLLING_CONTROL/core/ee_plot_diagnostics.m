function ee_plot_diagnostics(EE)
% EE-only plots. Padded bins are blank; each row may have different edges.
    if ~EE.enable || isempty(EE.edges), return; end
    C=EE.nchains-1;
    counts=EE.ring_count(2:end,:);
    for r=1:C
        edges=ee_edges_for_chain(EE,r+1); B=numel(edges)-1;
        counts(r,B+1:end)=NaN;
    end
    figure('Color','w','Name','EE availability and update accounting');
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
    nexttile;
    imagesc(counts,'AlphaData',isfinite(counts)); colorbar;
    xlabel('Ring index WITHIN pair'); ylabel('Recipient i; donor i+1');
    title('Donor time entries (edges may differ by row)');
    nexttile;
    available=EE.jump_proposed./max(EE.jump_triggered,1);
    conditional=EE.jump_accepted./max(EE.jump_proposed,1);
    overall=EE.jump_accepted./max(EE.jump_triggered,1);
    available(EE.jump_triggered==0)=NaN;
    conditional(EE.jump_proposed==0)=NaN;
    overall(EE.jump_triggered==0)=NaN;
    bar(100*[available(:) conditional(:) overall(:)]);
    ylim([0 100]); xlabel('Recipient'); ylabel('Percent');
    legend('Available / selected','Accepted / valid','Accepted / selected','Location','best');
    title('Availability and acceptance are separate');
    nexttile;
    for r=1:C
        selected=cumsum(EE.jump_history(:,r)~=0);
        accepted=cumsum(EE.jump_history(:,r)==1);
        curve=accepted./max(selected,1); curve(selected==0)=NaN;
        plot(curve); hold on;
    end
    xlabel('Iteration'); ylabel('Cumulative accepted / selected');
    title('Conditional on choosing EE; no convergence claim');
    nexttile;
    ee_by_chain=zeros(EE.nchains,1);
    ee_by_chain(1:C)=EE.jump_triggered(1:C);
    bar([EE.local_updates(:),ee_by_chain],'grouped');
    xlabel('Temperature chain'); ylabel('Number of updates');
    legend('Local RJ','Selected EE','Location','best');
    title('Mandatory local RJ plus supplemental EE');
end
