% ==============================
% 频散曲线计算函数
% ==============================
function results = PhaseDispersion(pd, orig_freq,t_py, mode, wave_type)
    
    % 尝试计算频散曲线
        disp_curve = pd(t_py, py.int(mode), wave_type);
        
        % 获取计算结果
        periods = double(py.array.array('d', disp_curve.period)); 
        velocities = double(py.array.array('d', disp_curve.velocity));
        
        % 转换到频率域
        freq_values = 1 ./ periods;          % 频率 (Hz)
        vel_values = velocities * 1000;    % 相速度 (m/s)
        
        % 创建NaN填充的完整数组
        full_vel = nan(size(orig_freq));    % 与原始频率等长的NaN数组
        
        % 找出原始频率中匹配的位置 (使用紧密容差)
        [~, idx] = ismembertol(freq_values, orig_freq, 1e-6, 'DataScale', 1);
        
        % 只填充匹配的位置
        valid_idx = idx(idx > 0);  % 确保索引有效
        full_vel(valid_idx) = vel_values(idx > 0);
        
        % 返回结果结构
        results = struct(...
            'freq', orig_freq, ...         % 完整的频率向量
            'velocity', full_vel, ...      % 带NaN填充的速度值
            'mode', mode, ...              % 模式阶数
            'wave', wave_type, ...         % 波类型
            'valid_indices', find(~isnan(full_vel)) ... % 有效点的索引
        );
end