function EE = ee_initialize(nsample, T, burn_in)
%EE_INITIALIZE DIM-inspired likelihood rings and EE diagnostics.
% Adaptation of DIM_MATLAB_Core ideas; see NOTICE_DIM.txt.
% Target of the UNCHANGED v4 RJ: p(m)*exp(-beta*like).
% Optional likelihood floors are supported; default off. No BSP or Schreck AEE.
    EE.version = 71;
    EE.enable = true;
    EE.energy_type = 'negative_log_likelihood';
    EE.update_mode = 'local_rj_then_optional_ee';
    EE.storage_mode = 'full_history_after_calibration';
    EE.nsample = nsample;
    EE.nchains = T;
    EE.nbins = 12;
    EE.requested_nbins = 12;
    EE.max_per_ring = Inf; % compatibility field; never evict a history entry
    EE.ring_thin = 1;      % archive every sweep; independent of posterior thin
    EE.calibration_start = max(1, floor(0.4*burn_in)+1);
    EE.calibration_end = max(EE.calibration_start, floor(0.8*burn_in));
    EE.jump_start = burn_in+1;
    EE.jump_interval = 1;
    EE.jump_probability = 0.20;
    EE.min_ring_size = 10;
    EE.fixed_edges = [];   % optional user-specified [-Inf ... Inf]
    EE.edges = [];
    EE.energy_buffer = [];
    EE.rings = cell(T, EE.nbins);
    EE.ring_count = zeros(T, EE.nbins);
    EE.ring_seen = zeros(T, EE.nbins, 'uint64');
    EE.jump_triggered = zeros(1, max(T-1,1));
    EE.jump_unavailable = zeros(1, max(T-1,1));
    EE.jump_proposed = zeros(1, max(T-1,1));
    EE.jump_accepted = zeros(1, max(T-1,1));
    EE.jump_crossdim_proposed = zeros(1, max(T-1,1));
    EE.jump_crossdim_accepted = zeros(1, max(T-1,1));
    EE.local_updates = zeros(1,T);
    % Raw likelihood energy and dimension immediately before/after each
    % kernel. These arrays distinguish local progress from supplemental EE.
    EE.energy_before_local = nan(nsample,T);
    EE.energy_after_local = nan(nsample,T);
    EE.energy_after_ee = nan(nsample,T);
    EE.npt_before_local = nan(nsample,T);
    EE.npt_after_local = nan(nsample,T);
    EE.npt_after_ee = nan(nsample,T);
    EE.jump_history = zeros(nsample,max(T-1,1),'int8');
    EE.jump_candidate_energy_delta = nan(nsample,max(T-1,1));
    EE.jump_candidate_npt_delta = nan(nsample,max(T-1,1));
    EE.energy_history = nan(nsample,T);
    EE.ring_total_history = zeros(nsample,T,'uint32');
    EE.ring_seen_total_history = zeros(nsample,T,'uint32');
    EE.current_energy = nan(nsample,max(T-1,1));
    EE.candidate_energy = nan(nsample,max(T-1,1));
    EE.candidate_iteration = nan(nsample,max(T-1,1));
    EE.log_acceptance = nan(nsample,max(T-1,1));
    EE.selected_ring = nan(nsample,max(T-1,1));
    EE.archive_start = NaN;
    EE.archive_last_iteration = 0;
    EE.boundaries_frozen_at = NaN;
    EE.configured = false;
    EE.truncation_enable=false;
    EE.floor_calibration_start=1;
    EE.floor_calibration_end=1;
    EE.floor_quantiles=linspace(.2,.8,max(EE.nchains-1,1));
    EE.energy_floors=-Inf(1,EE.nchains);
    EE.floor_frozen_at=NaN;
    EE.refine_low_energy=false;
    % Legacy default retained for contract tests. Main config selects pairwise.
    EE.calibration_mode='pooled';
    EE.merge_sparse=false;
    EE.min_pilot_donor_count=20;
    EE.pair_edges=cell(1,max(T-1,1));
    EE.pair_nbins=zeros(1,max(T-1,1));
    EE.chain_edges=cell(1,T);
    EE.calibration_report=cell(1,max(T-1,1));
    EE.diagnostic_priors=[];
    EE.diagnostic_grid=[];
    EE.donor_count_at_selection=nan(nsample,max(T-1,1));
    EE.unavailable_reason=zeros(nsample,max(T-1,1),'uint8');
    EE.current_npt=nan(nsample,max(T-1,1));
    EE.candidate_npt=nan(nsample,max(T-1,1));
    EE.profile_rms_delta=nan(nsample,max(T-1,1));
    EE.profile_max_delta=nan(nsample,max(T-1,1));

    % E7 defaults: two independent memories.  Energy boundaries use a
    % rolling calibration window; proposals use a larger complete-state FIFO.
    EE.adapt_window=4000;
    EE.adapt_interval=2000;
    EE.archive_window=8000;
    EE.reset_iteration=max(2,burn_in-2000);
    EE.update_until_end=true;
    EE.adaptation_policy='continuous';
    EE.postreset_calibration='rolling_window';
    EE.archive_mode='rolling_fifo';
    EE.reset_archive_once=true;

end
