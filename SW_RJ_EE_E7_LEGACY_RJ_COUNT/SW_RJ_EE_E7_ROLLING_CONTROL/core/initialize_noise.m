function L_chol = initialize_noise(noise,data_mode)


   sigma_b = noise.sigma_b;        % 基础噪声标准差 (m/s)
   a = noise.a;                    % 数据相关噪声缩放因子
   rho = noise.rho;                % 相邻数据相关系数

 % 计算各数据点噪声标准差 (σ_i = σ_b + a*d_i)
    obs_vel = data_mode.data_mode1;  % 获取观测速度值
    sigma_i = sigma_b + a * obs_vel; % 计算各频率点的噪声标准差
    
    % 构建指数衰减相关矩阵 (R_ij = ρ^|i-j|)
    n = length(data_mode.freq);
    L = tril(ones(n));                % 下三角索引矩阵
    corr_matrix = rho.^abs(L - L');   % 指数衰减相关矩阵
    
    % 构建完整协方差矩阵 (C = diag(σ_i) * corr_matrix * diag(σ_j))
    C = diag(sigma_i) * corr_matrix * diag(sigma_i);
    
    % Cholesky分解（用于行列式计算和逆矩阵）
    [L_chol, p] = chol(C, 'lower');
    if p > 0
        error('协方差矩阵不正定！');
    end