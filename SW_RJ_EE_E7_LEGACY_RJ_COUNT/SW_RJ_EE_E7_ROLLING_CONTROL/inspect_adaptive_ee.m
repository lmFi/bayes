function inspect_adaptive_ee(file)
% Show epochs and post-burn occupancy using saved results (no Python).
    if nargin<1
        [f,d]=uigetfile('*.mat'); if isequal(f,0), return; end
        file=fullfile(d,f);
    end
    S=load(file,'EE','burn_in','result'); E=S.EE;
    if ~isfield(E,'edge_updates'), error('Not an adaptive result.'); end
    if isfield(E,'reset_iteration')
        fprintf('One-time archive reset: %d; posterior starts: %d\n', ...
            E.reset_iteration,S.burn_in+1);
    else
        fprintf('Legacy final freeze: %d; posterior starts: %d\n', ...
            E.boundaries_frozen_at,S.burn_in+1);
    end
    if isfield(E,'archive_window')
        fprintf('Proposal archive: %s, capacity %d states/chain; reset at %g\n', ...
            E.storage_mode,E.archive_window,E.archive_reset_at);
        fprintf('  active:'); fprintf(' %d',E.archive_count); fprintf('\n');
        fprintf('  total seen:'); fprintf(' %d',E.archive_seen); fprintf('\n');
        fprintf('  FIFO-evicted after reset:');
        fprintf(' %d',E.archive_dropped); fprintf('\n');
        if isfield(E,'archive_dropped_before_reset')
            fprintf('  FIFO-evicted before reset:');
            fprintf(' %d',E.archive_dropped_before_reset); fprintf('\n');
        end
        fprintf('  discarded at reset:'); fprintf(' %d',E.archive_reset_discarded); fprintf('\n');
    end
    for j=1:numel(E.edge_updates)
        u=E.edge_updates(j);
        reset=false; if isfield(u,'archive_reset'), reset=u.archive_reset; end
        fprintf('Epoch %d: edges updated at %d, active from %d; pilot %d:%d; archive reset=%d\n', ...
            j,u.iteration,u.active_from,u.pilot_start,u.pilot_end,reset);
        for t=1:E.nchains-1
            use=E.edge_epoch_history==j & E.jump_history(:,t)~=0;
            valid=use & abs(E.jump_history(:,t))==1;
            fprintf('  %d<-%d: selected=%d valid=%d accepted=%d; boundaries:', ...
                t,t+1,sum(use),sum(valid),sum(use & E.jump_history(:,t)==1));
            fprintf(' %g',u.edges{t}); fprintf('\n');
        end
    end
    fprintf('Post-burn selected ring counts (ring indices are epoch-specific):\n');
    for t=1:E.nchains-1
        k=E.selected_ring(S.burn_in+1:end,t); k=k(isfinite(k));
        fprintf('  chain %d:',t);
        for b=1:E.pair_nbins(t), fprintf(' ring%d=%d',b,sum(k==b)); end
        fprintf('\n');
    end
end
