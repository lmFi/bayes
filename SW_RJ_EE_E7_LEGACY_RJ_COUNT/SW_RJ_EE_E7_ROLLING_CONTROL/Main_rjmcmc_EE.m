function result_file=Main_rjmcmc_EE(run_cfg)
%% ========================================================================
%% 多模式瑞雷波频散曲线的跨维MCMC反演
% 清除工作空间并关闭所有图形
root=fileparts(mfilename('fullpath'));
addpath(root,'-begin'); addpath(fullfile(root,'core'),'-begin');
rehash path;
if nargin<1, run_cfg=rj_ee_options; end
run_cfg=resolve_ee_config(run_cfg);
if ~isfolder(run_cfg.output_dir), mkdir(run_cfg.output_dir); end
[~,token]=fileparts(tempname(run_cfg.output_dir));
outfile=sprintf('%s_%s_seed%d_%s_%s.mat',run_cfg.case_name, ...
    run_cfg.run_label,run_cfg.seed,datestr(now,'yyyymmdd_HHMMSS_FFF'),token);
result_file=fullfile(run_cfg.output_dir,outfile);
[data,data_mode,fit_error]=load_ee_observations(run_cfg);
Model=run_cfg.Model;
forward_failure_log('reset');
initialize_disba;
fprintf('Data: %s\n',run_cfg.data_file);
fprintf('Case=%s seed=%d; sigma=max(%.4g*abs(c),%.4g m/s); total K=%d..%d.\n', ...
    run_cfg.case_name,run_cfg.seed,run_cfg.relative_error,run_cfg.error_floor, ...
    run_cfg.npt_min+1,run_cfg.npt_max+1);
fprintf('A=%d EE=%d PT=%d floor=%d; birth %.4g/%.4g, small weight %.3g.\n', ...
    run_cfg.enable_a,run_cfg.enable_ee,run_cfg.enable_pt,run_cfg.truncation_enable, ...
    run_cfg.birth_small,run_cfg.birth_large,run_cfg.birth_small_weight);
fprintf('RJ state measure: %s\n',run_cfg.rj_state_measure);

% 设置随机数生成器（确保结果可复现）
rng('default');
num_rng=run_cfg.seed;
rng(num_rng); 

%% ========================================================================
%% 反演参数设置
% MCMC采样参数
burn_in = run_cfg.burn_in;  % 预热期样本数
nsample = run_cfg.nsample; % 总样本数

% 深度先验范围
priors.depth_min = run_cfg.depth_min;  
priors.depth_max = run_cfg.depth_max;

% 可变层数范围
priors.npt_min = run_cfg.npt_min;  
priors.npt_max = run_cfg.npt_max;
% 默认复现初始版Birth/Death的组合因子；可通过配置切回E7的无标签计量。
priors.rj_state_measure = run_cfg.rj_state_measure;
priors.log_p_npt = repmat( ...
    -log(priors.npt_max - priors.npt_min + 1), ...
    1, priors.npt_max - priors.npt_min + 1);
if ~isempty(run_cfg.npt_prior), priors.log_p_npt=log(run_cfg.npt_prior); end
priors.proposal_prob_birth = 1/3;
priors.proposal_prob_death = 1/3;
priors.proposal_prob_move = 1/3;

% 固定层数
priors.num_layers = 1;

% 层边界深度（最后一层深度无限）
priors.layer_depths = zeros(priors.num_layers-1, 1); 

% 各层波速范围
priors.vsmin = zeros(priors.num_layers, 1);
priors.vsmax = zeros(priors.num_layers, 1);
priors.vsmin(1) = run_cfg.vs_min; 
priors.vsmax(1) = run_cfg.vs_max;

% Vp/Vs关系常数：与本算例五层理论模型 Vp=2*Vs 保持一致。
priors.vp_vs=run_cfg.vp_vs;

% 初始可变层数
npt_init = run_cfg.npt_init; 

% 提议分布标准差
sigma.change_vs = run_cfg.change_vs;      % 波速变化标准差
sigma.move_depth = run_cfg.move_depth;      % 深度移动标准差
sigma.birth_mixture=run_cfg.birth_mixture;
sigma.birth_small=run_cfg.birth_small;
sigma.birth_small_weight=run_cfg.birth_small_weight;
sigma.birth_depth=struct('enabled',run_cfg.enable_a, ...
    'local_weight',run_cfg.a_local_weight,'halfwidth',run_cfg.a_halfwidth);
sigma.birth_vs = run_cfg.birth_large;      % 新生层波速标准差

%% ========================================================================
%% 次要参数设置
% 模型范围
x_min = priors.depth_min;
x_max = priors.depth_max;

% 离散化参数
dis = run_cfg.dis;   % 深度离散点数
dis_y = run_cfg.dis_y; % 波速离散点数

% 显示和细化参数
show = run_cfg.show;  % 显示统计信息的间隔
thin = run_cfg.thin;   % 少量抽稀；是否足够仍应通过自相关和ESS判断

if burn_in >= nsample
    error('burn_in 必须小于 nsample。');
end
if thin < 1 || thin ~= round(thin)
    error('thin 必须为正整数。');
end

% 创建离散网格
x = linspace(x_min, x_max, dis);                     % 深度网格
% 计算样本数量
n_keep = floor(nsample / thin) - floor(burn_in / thin);
num = max(1, ceil(0.025 * n_keep));                    % each posterior tail
% 网格边界
depth_edge = 0.5 * (x(1:end-1) + x(2:end));

%% ========================================================================
%% 设置横波速度搜索范围
initial_model = linspace(priors.vsmin(1), priors.vsmax(1), dis)';
% initial_model = initial_model(:,2)';
priors = velocity_search_range(priors, x, run_cfg.search_range, ...
     'InitialModel', initial_model,...
     'MinRatio', run_cfg.min_ratio, 'MaxRatio', run_cfg.max_ratio);
% priors = velocity_search_range(priors, x, 'fixed', ...
%      'InitialModel', initial_model,...
%      'MinRatio', 1, 'MaxRatio', 1);
%% 先验部分
% 深度相关速度先验：用于实际采样，不只是绘图
% z = priors.x(:);

% priors.vsmin_profile = max( ...
%     priors.vsmin(1), 200 + 3*z);
% 
% priors.vsmax_profile = min( ...
%     priors.vsmax(1), 650 + 10*z);

% assert(all(priors.vsmin_profile < priors.vsmax_profile), ...
%     '速度先验上下界存在交叉。');

y = linspace(min(priors.vsmin), max(priors.vsmax), dis_y); % 波速网格
vs_edge = 0.5 * (y(1:end-1) + y(2:end));
%% ========================================================================
%% 并行回火设置
T=numel(run_cfg.temperatures);
beta=1./run_cfg.temperatures;
fprintf('Temperatures:'); fprintf(' %g',run_cfg.temperatures); fprintf('\n');
% Kou等人的标准EE框架依赖多条温度辅助链，但不要求链间交换。
% 为单独检验RJ+EE效果，v3默认关闭PT交换；如需组合实验可改为true。
enable_temperature_swaps = run_cfg.enable_pt;
swap_interval = run_cfg.swap_interval;
% Temp = 1;

%% ========================================================================
%% Equi-Energy 能量环设置
% 能量环使用 E=like（高斯负对数似然失配）。这与当前程序“只对似然
% 回火、先验不回火”的目标分布保持一致。
% ---- DIM-inspired EE options: all non-EE v4 settings above are untouched ----
EE = ee_initialize(nsample, T, burn_in);
EE.enable = run_cfg.enable_ee;
EE.nbins = run_cfg.ee_nbins;
EE.jump_probability = run_cfg.ee_probability;
EE.jump_interval = 1;
EE.min_ring_size = run_cfg.ee_min_ring_size;
EE.calibration_start = run_cfg.ee_calibration_start;
EE.calibration_end = run_cfg.ee_calibration_end;
EE.jump_start = run_cfg.ee_jump_start;       % 7001:8500 fills history; collect after 10000
EE.ring_thin = 1;          % archive every completed iteration (posterior thin unchanged)
EE.max_per_ring = Inf;     % fixed-ring compatibility; adaptive mode uses archive_window
EE.fixed_edges = run_cfg.ee_fixed_edges;      % E7 adaptive mode requires []
EE.truncation_enable = run_cfg.truncation_enable; % independently disable for ablation
EE.floor_calibration_start = run_cfg.floor_calibration_start;
EE.floor_calibration_end = run_cfg.floor_calibration_end; % then 4001:5000 settles truncated hot chains
EE.floor_quantiles = run_cfg.floor_quantiles; % cold-pilot quantiles for hot chains 2,3,4
EE.refine_low_energy = run_cfg.ee_refine_low_energy; % extra 6 low-energy boundaries; actual count printed
EE.calibration_mode=run_cfg.ee_calibration_mode;
EE.merge_sparse=run_cfg.ee_merge_sparse;
EE.min_pilot_donor_count=run_cfg.ee_min_pilot_donor_count;
EE.adapt_enable=run_cfg.ee_adapt_enable;
EE.adapt_window=run_cfg.ee_adapt_window;
EE.adapt_interval=run_cfg.ee_adapt_interval;
EE.reset_iteration=run_cfg.ee_reset_iteration;
EE.archive_window=run_cfg.ee_archive_window;
EE.adaptation_policy=run_cfg.ee_adaptation_policy;
EE.update_until_end=run_cfg.ee_update_until_end;
EE.postreset_calibration=run_cfg.ee_postreset_calibration;
EE.archive_mode=run_cfg.ee_archive_mode;
EE.reset_archive_once=run_cfg.ee_reset_archive_once;
EE.diagnostic_priors=priors;
EE.diagnostic_grid=x;
EE = ee_dim_configure(EE, nsample, T, burn_in);
run_manifest=ee_run_manifest(root,run_cfg);

tic  % 开始计时

% 初始化变量结构体
[variable] = initialize_variable(dis, num);

% 初始化结果结构体
[result] = initialize_result(dis, dis_y, priors, nsample, T, num, n_keep);
result.npt_all=zeros(nsample,T);
result.kept_npt=zeros(n_keep,1);
result.kept_iteration=zeros(n_keep,1);
result.kept_depths=zeros(priors.npt_max+priors.num_layers,n_keep);
result.kept_vs=zeros(priors.npt_max+priors.num_layers,n_keep);

% 初始化前向模型矩阵
forward_model = zeros(data_mode.nd, data_mode.dc_num+1, T);

% 初始化操作计数器
[Num] = monitoring(T);

%% ========================================================================
%% 初始化马尔可夫链
% 初始化模型参数矩阵
nuclei_vs = zeros(priors.npt_max + priors.num_layers, T);
nuclei_depths = zeros(priors.npt_max + priors.num_layers, T);

% 初始化似然值和层数向量
like = zeros(1, T);
npt = zeros(1, T);

% 初始化链的第一个模型
[nuclei_vs, nuclei_depths, npt, like, like_best, priors_OK, forward_model] = ...
    initialize_chain(npt_init, priors, data_mode, fit_error, ...
    nuclei_vs, nuclei_depths, npt, like, T,x);

[best_mode, forward_model_best] = best_mode_init(nuclei_depths, nuclei_vs, npt, like, forward_model);

%% ========================================================================
%% MCMC采样主循环
fprintf('Total number of samples %i\n', nsample);
fprintf('Acceptance rates:\n');
fprintf('Iteration  Change Vs    Move Depth    Birth     Death\n');

for s = 1:nsample
    out = 1;  % 模型有效性标志
    
    % 显示采样进度和接受率
    if mod(s, show) == 0
        fprintf('%7i     %5.2f         %5.2f       %5.2f     %5.2f\n', ...
            s, 100*Num(1).AcV/Num(1).PV, 100*Num(1).AP/Num(1).PP, ...
            100*Num(1).AB/Num(1).PB, 100*Num(1).AD/Num(1).PD);
    end
    
    %% 阶段1：每条温度链必做一次局部RJMCMC
    % E5不再让EE占用局部RJ更新机会。这一阶段与EE关闭时完全相同：
    % 每条链每轮恰好执行一次原有RJ_C_mian。Birth/Death/Move/Change
    % 的提议、先验和接受率都没有在本版修改。
    EE.energy_before_local(s,:) = like(:).';
    EE.npt_before_local(s,:) = npt(:).';
    % 临时
    if s <= 75
    st = rng;
    debug_rng_before{s} = st.State;
    debug_like_before(s) = like(1);
    debug_npt_before(s) = npt(1);
    end
    %% 并行计算 不超过机器的核数 多了之后有荣誉
    for t = 1:T
        local_priors=priors;
        local_priors.ee_energy_floor=EE.energy_floors(t);
        [nuclei_depths(:, t), nuclei_vs(:, t), ...
            forward_model(:, :, t), like(:, t), npt(:, t), Num(t)] = ...
            RJ_C_mian(nuclei_vs(:, t), nuclei_depths(:, t), ...
            like(:, t), npt(:, t), local_priors, sigma, s, Num(t), out, ...
            data_mode, fit_error, beta(:, t), x, ...
            forward_model(:, :, t));
        EE.local_updates(t) = EE.local_updates(t) + 1;
    end
    % 临时
    if s <= 75
    st = rng;
    debug_rng_after{s} = st.State;
    debug_like_after(s) = like(1);
    debug_npt_after(s) = npt(1);
    end
    save('debug75.mat', ...
    'debug_rng_before','debug_rng_after', ...
    'debug_like_before','debug_like_after', ...
    'debug_npt_before','debug_npt_after');

    
    EE.energy_after_local(s,:) = like(:).';
    EE.npt_after_local(s,:) = npt(:).';

    %% 阶段2：在局部RJ之后，以固定概率追加一次EE尝试
    % EE是补充转移，不是主更新的替代品。供体候选仍只来自
    % ee_ring_update在以前轮次写入的历史，所以不会读到本轮尚未完成
    % 的状态。未选中、不可用或拒绝都保留刚刚RJ更新后的状态。
    for t = 1:T
        [nuclei_depths, nuclei_vs, npt, like, forward_model, ...
            ~, EE] = ee_jump(nuclei_depths, nuclei_vs, ...
            npt, like, forward_model, beta, EE, s, t);
    end
    EE.energy_after_ee(s,:) = like(:).';
    EE.npt_after_ee(s,:) = npt(:).';

    %% 可选温度交换（默认关闭，不与EE效果混合）
    if enable_temperature_swaps && mod(s, swap_interval) == 0
        swap_event = s / swap_interval;
        [nuclei_depths, nuclei_vs, npt, like, forward_model] = ...
            non_Re_tem_swap_3(nuclei_depths, nuclei_vs, npt, like, ...
            beta, T, swap_event, forward_model, priors, EE.energy_floors);
    end

    %% 将接受/拒绝判断后的最终状态写入能量环
    % EE候选只来自以前的历史环；本轮最终状态在全部更新结束后只入库一次。
    EE = ee_ring_update(EE, s, nuclei_depths, nuclei_vs, npt, ...
        like, forward_model);
  
    % 存储主链（温度=1）的当前状态
    chain.nuclei_depths = nuclei_depths(:, 1);
    chain.nuclei_vs = nuclei_vs(:, 1);
    chain.like = like(:, 1);
    chain.npt = npt(:, 1);
    chain.forward_model = forward_model(:, :, 1);
    [best_mode, forward_model_best] = best_mode_update( ...
        best_mode, chain, 1, forward_model, forward_model_best);
    %% 样本收集（预热期后）
    % 计算当前模型的置信密度矩阵

    % [N] = parameter_N(dis, nuclei_depths, nuclei_vs, priors, variable, x, y, chain.npt);           
    % 
    % % 更新最佳模型
    % [best_mode, forward_model_best] = best_mode_update(best_mode, chain, priors_OK, forward_model, forward_model_best);

    % 收集样本（预热期后且满足细化间隔）
    if s > burn_in && mod(s, thin) == 0
    [N] = parameter_N(dis, nuclei_depths, nuclei_vs, priors, variable, x, y, chain.npt);           
    
        [result, variable, priors] = ...
            Collect_samples(dis, priors, variable, result, x, chain, best_mode, num, N);
        q=variable.counter_basic;
        result.kept_npt(q)=chain.npt;
        result.kept_iteration(q)=s;
        result.kept_depths(:,q)=chain.nuclei_depths;
        result.kept_vs(:,q)=chain.nuclei_vs;
    end
    
    %% 存储链状态
    result.cov(s) = chain.like;                           % 当前似然值
    result.nnuclei(s) = chain.npt + priors.num_layers;    % 当前总层数
    result.npt_all(s,:)=npt;
    result.U(s,:)=-beta.*max(like,EE.energy_floors);
    result.cov_all(s, :) = like;                          % 所有链的似然值

end  % 结束MCMC采样

% E5合同：每条链每轮恰好一次局部RJ；EE计数是额外尝试。
if any(EE.local_updates ~= nsample)
    error('Main_rjmcmc:SequentialCountMismatch', ...
        '局部RJ更新计数不等于总迭代数，请检查顺序更新逻辑。');
end

sampling_seconds=toc;  % 结束计时
fprintf('Sampling time %.3f s\n',sampling_seconds);
fprintf('Retained cold-chain posterior samples: %d\n', ...
    variable.counter_basic);
for t = 1:(T-1)
    fprintf(['EE chain %d <- %d: selected=%d, unavailable/self-loop=%d, ' ...
        'valid proposals=%d, accepted=%d, cross-dimensional ' ...
        'proposed=%d, accepted=%d\n'], ...
        t, t+1, EE.jump_triggered(t), EE.jump_unavailable(t), ...
        EE.jump_proposed(t), EE.jump_accepted(t), ...
        EE.jump_crossdim_proposed(t), EE.jump_crossdim_accepted(t));
end
fprintf('Local RJ updates per chain:');
fprintf(' %d', EE.local_updates);
fprintf('\n');
fprintf('EE attempts above are supplemental; they do not replace local RJ updates.\n');
if EE.adapt_enable && EE.enable
    clean_seen=nsample-EE.reset_iteration;
    expected_active=min(clean_seen,EE.archive_window);
    expected_dropped=max(0,clean_seen-EE.archive_window);
    if EE.archive_reset_at~=EE.reset_iteration || ...
            any(EE.archive_count~=expected_active) || ...
            any(double(EE.archive_dropped)~=expected_dropped)
        error('Main_rjmcmc:E7ArchiveContract', ...
            ['E7 FIFO contract failed: expected one reset and exactly the ', ...
             'most recent archive_window complete states.']);
    end
    first_active=max(EE.reset_iteration+1,nsample-EE.archive_window+1);
    fprintf(['E7 FIFO archive per chain: %d active states (iterations %d:%d); ', ...
        'older clean states evicted=%d; edge policy=%s.\n'], ...
        expected_active,first_active,nsample,expected_dropped,EE.adaptation_policy);
end

%% ========================================================================
%% 后处理与结果分析
% 计算平均模型和最佳模型速度剖面
[result, best_model_vs] = Average_confidence(result, variable, priors, dis, best_mode, x);

% 计算置信密度矩阵
[CI_density_limitN, CI_density_limit] = CI_density(result, variable, dis, x, y);

% 计算最大后验波速剖面
[vs_mode_n0] = Depth_best_vs(dis, dis_y, CI_density_limit, vs_edge);

% 计算中位数波速剖面
[vs_median] = Depth_median_vs(dis, dis_y, CI_density_limit, vs_edge);

%% ========================================================================
%% 保存结果
print_rj_reasons(Num);
forward_diagnostics=forward_failure_log('get');
disp(forward_diagnostics);
[ee_summary,ee_events,ee_calibration]=ee_result_tables(EE,burn_in);
summary=ee_inversion_summary(result,Model,x,run_cfg,sampling_seconds,forward_diagnostics,ee_summary);
disp(ee_summary);
% Keep every old plotting input in the MAT, but omit runtime history by default.
if ~run_cfg.save_history
    EE=rmfield(EE,'rings');
    if isfield(EE,'archive'), EE=rmfield(EE,'archive'); end
end
EE.history_saved=run_cfg.save_history;
fields={'result','variable','priors','sigma','Model','x','y','vs_mode_n0', ...
    'best_model_vs','vs_median','vs_edge','depth_edge','CI_density_limitN', ...
    'CI_density_limit','data_mode','data','fit_error','forward_model_best', ...
    'best_mode','burn_in','nsample','thin','num_rng','beta','T','Num','EE', ...
    'run_cfg','run_manifest','summary','ee_summary','ee_events','ee_calibration', ...
    'sampling_seconds','forward_diagnostics','result_file'};
% save is before graphics, so a graphics failure does not lose sampling output.
if run_cfg.save_history
    save(result_file,fields{:},'-v7.3');
else
    save(result_file,fields{:},'-v7');
end
fprintf('Saved: %s\n',result_file);
if run_cfg.save_csv
    stem=result_file(1:end-4);
    writetable(ee_summary,[stem '_ee_summary.csv']);
    writetable(ee_events,[stem '_ee_events.csv']);
    writetable(ee_calibration,[stem '_ee_calibration.csv']);
    writetable(struct2table(summary),[stem '_summary.csv']);
end

%% ========================================================================
%% 结果可视化
if run_cfg.make_plots
try

% 对最大后验与中位数剖面做轻微平滑，仅用于显示。
vs_mode_plot = Filter_Local_median(vs_mode_n0, 31, 0.01, 0.05);
vs_median_plot = Filter_Local_median(vs_median, 31, 0.01, 0.05);
vs_mean_plot = Filter_mean5_3(result.AV, 20);

% 图1：速度剖面、Vs后验密度与界面概率。
plot_velocity_posterior(priors, x, Model, vs_mode_plot, ...
    best_model_vs, vs_mean_plot, vs_median_plot, vs_edge, depth_edge, ...
    CI_density_limitN, result, variable);

% 图2：观测频散点与最佳拟合样本的正演频散曲线。
plot_dispersion_fit(data_mode, forward_model_best);

% 图3：收敛轨迹、界面深度密度与模型维数后验概率。
plot_mcmc_diagnostics(result, variable, priors, Model, burn_in, nsample);

%% Equi-Energy 能量环诊断图
ee_plot_diagnostics(EE)
plot_ee_dim_extra(EE); % Additional EE diagnostics; original figure calls unchanged

catch ME
    warning('Plots:Failed','Result already saved to %s. Plot error: %s',result_file,ME.message);
end
end % optional plots

end
