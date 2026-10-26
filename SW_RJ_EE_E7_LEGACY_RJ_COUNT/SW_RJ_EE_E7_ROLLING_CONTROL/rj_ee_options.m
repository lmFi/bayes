% 能量环持续滚动更新
% 每轮先完成原始局部 RJ，再以 5% 概率追加一次 EE；能量边界持续自适应；候选库采用最近 8000 个状态 FIFO"的运行策略。
function cfg = rj_ee_options(case_name,ee_policy)
% Single configuration entry. Units: m, m/s, Hz.
% npt=floating nuclei; num_layers=1 => total cells K=npt+1.
% Model is a plotting/check reference, NEVER used to train proposals.
    if nargin<1, case_name='five'; end
    if nargin<2, ee_policy='continuous'; end
    root=fileparts(mfilename('fullpath'));
    cfg.case_name=lower(char(case_name));
    
    cfg.seed=25;
    
    cfg.nsample=50000;
    
    cfg.burn_in=10000;
    
    cfg.thin=50;                    % posterior only; never thin EE history
    cfg.depth_min=0;
    cfg.depth_max=25;

    cfg.npt_min=1;
    cfg.npt_max=9;                  % total 2..19 cells

    % 经验
    cfg.npt_init=5;
    %% 层数先验：K=3～8高概率，区间外指数下降
    npt_values = cfg.npt_min:cfg.npt_max;
    K_values = npt_values + 1;

    distance_to_range = ...
    max(3-K_values,0) + max(K_values-9,0);

    lambda_inside = 0.50;   % 每增加一层，权重乘 exp(-0.30)
    lambda_outside = 5.0;   % 超出3～8层后强烈下降

    logw = ...
    -lambda_inside .* max(K_values-3,0) ...
    -lambda_outside .* distance_to_range;

    logw = logw - max(logw);
    w = exp(logw);
    cfg.npt_prior = w ./ sum(w)
    % cfg.npt_prior=[];               % [] gives constant log_p_npt; interpretation depends on state measure
    % npt_values = cfg.npt_min:cfg.npt_max;
    % K_values = npt_values + 1;
    % 
    % distance_to_range = ...
    % max(3-K_values,0) + max(K_values-8,0);
    % 
    % lambda_outside = 2.0;
    % 
    % logw = -lambda_outside .* distance_to_range;
    % 
    % logw = logw - max(logw);
    % w = exp(logw);
    % 
    % cfg.npt_prior = w ./ sum(w);
 %% 
    cfg.rj_state_measure='unordered_iid_uniform_depth'; % initial RJ acceptance for regression; use unordered for count-prior inference
    
    cfg.vs_min=200;
    cfg.vs_max=900;

    cfg.vp_vs=1.732;
    cfg.search_range='increasing';  % baseline bounds; NOT monotone Vs
    cfg.min_ratio=0.7;
    cfg.max_ratio=3;
    cfg.mode_indices=[0 1 2];
    % 一定一定要做敏感性实验  导致层数很黏。 为什么 Death 后会 missing_prediction？
    cfg.relative_error=0.02;         % likelihood std; does NOT add noise
    cfg.error_floor=2;              % m/s, strictly positive

    cfg.birth_mixture=false;

    cfg.birth_small=20;

    cfg.birth_large=100;
   
    % 80%的小步长Birth负责生成容易接受的近似分裂；
    % 20%的大步长Birth有机会直接发现 500→300、400→700 这种明显速度差；
    cfg.birth_small_weight=0.8;

    cfg.change_vs = 20;
    % 深度步长改成0.5 m，更适合定位2、4、8、10 m界面。
    cfg.move_depth= 1;
    %% 看看这个改进有没有用
    % 先不要同时加入局部深度Birth，避免无法判断改善来自Birth混合还是EE。
    cfg.enable_a=false;             % optional Route A

    % local_weight = 0.5 表示：如果启用局部 Birth，
    % 那么有 50% 概率从已有核附近出生，另外 50% 仍然在整个深度范围均匀出生。
    cfg.a_local_weight=0.5;
    
    % halfwidth = 2 表示局部出生窗口的"半宽"是 2 m。
    cfg.a_halfwidth=2;              % m
   
    % 网上增加
    cfg.temperatures=[1 2 4 8];
    
    cfg.enable_pt=false;

    cfg.swap_interval=100;
    
    %% 能量环部分
    %  开启等能量跳跃。
    cfg.enable_ee=true;
    % 每轮完成局部 RJ 后，以 5% 概率尝试 EE。 
    % 参数过大：EE 可能频繁覆盖刚刚完成的局部调整；冷链更强地继承热链维度；
    % 层数轨迹可能过多受历史库支配；- 计算和统计相关性也可能增大。
    % 调整一下敏感性
    cfg.ee_probability=0.02;        % supplemental EE after mandatory local RJ
    
    % 
    cfg.ee_nbins=8;                % ties/merging may reduce actual number

    cfg.ee_min_ring_size=10;
    % 1-1000轮局部RJ，积累能量
    cfg.ee_calibration_start=1001;
    
    % 1001～3000初始成对分环校准 3000形成第一套边界
    cfg.ee_calibration_end=6000;
    
    % 3001～4000填充EE候选 4001开始每轮局部RJ，额外以0.10概率尝试EE
    cfg.ee_jump_start=8001;         % fill history 3001:4000
    
    cfg.ee_calibration_mode='pairwise'; % 'pooled' = shared calibration

    cfg.ee_refine_low_energy=false; % legacy six extra low-energy cuts

    cfg.ee_merge_sparse=true;      % calibration only; pairwise only

    cfg.ee_min_pilot_donor_count=20; % time entries, NOT effective samples

    cfg.ee_adapt_enable=true;

    cfg.ee_adapt_window=4000;       % 每次只用最近4000轮能量校准边界

    cfg.ee_adapt_interval=4000;     % 每4000轮更新一次边界

    % 两个对照组都在第18000轮先更新边界，再删除此前全部EE候选。
    % continuous：此后仍每2000轮按最近4000轮能量更新边界。
    % frozen：第18000轮以后边界固定，但候选FIFO仍持续更新。

    % 
   cfg.ee_reset_iteration=80000;

    cfg.ee_reset_archive_once=true;

    cfg.ee_archive_window=4000;     % 每条链最近8000个完整状态，严格FIFO

    cfg.ee_adaptation_policy=lower(char(ee_policy)); % continuous / frozen

    cfg.ee_update_until_end=strcmp(cfg.ee_adaptation_policy,'continuous');
    % 禁止后验阶段继续更新边界
    % cfg.ee_update_until_end= false;

    cfg.ee_postreset_calibration='rolling_window';

    cfg.ee_archive_mode='rolling_fifo';

    cfg.ee_fixed_edges=[];          % optional common [-Inf ... Inf]
     %% 不使用似然截断
    cfg.truncation_enable=false;
     % 当前不生效，仅作为备用配置
    cfg.floor_calibration_start=1001;

    cfg.floor_calibration_end=4000;

    cfg.floor_quantiles=[0.2 0.5 0.8];

    cfg.dis=150;
    cfg.dis_y=160;
    cfg.show=1000;
    cfg.make_plots=true;
    cfg.save_history=false;         % MAT output only; runtime FIFO remains complete
    cfg.save_csv=true;
    cfg.run_label=['E7_' cfg.ee_adaptation_policy '_4000E_8000S'];
    cfg.output_dir=fullfile(root,'results');
    switch cfg.case_name
        case 'five'
            cfg.data_file=fullfile(root,'data','six_layer_rayleigh.txt');
            cfg.Model=[500 300 400 700  800 2 2 4 8];
        case 'seven'
            cfg.data_file=fullfile(root,'data','seven_layer_rayleigh.txt');
            cfg.Model=[400 450 500 550 600 700 900 4 5 5 6 7 6];
            cfg.depth_max=40;
            cfg.npt_max=10;
            cfg.npt_init=3; % starting complexity only; dimension stays variable
        otherwise
            error('Config:Case','Use rj_ee_options(''five'') or (''seven'').');
    end
end
