function [vs_mode_n0] = Depth_best_vs(dis, dis_y, CI_density_limit, vs_edge)
    % DEPTH_BEST_VS - 从置信密度矩阵中提取各深度点的最佳波速值
    %
    % 输入参数:
    %   dis                - 深度离散点数（垂直分辨率）
    %   dis_y              - 波速离散点数（水平分辨率）
    %   CI_density_limit   - 置信密度矩阵（归一化后）
    %   vs_edge            - 波速网格边界向量
    %
    % 输出参数:
    %   vs_mode_n0         - 各深度点的最佳波速值（最大密度对应的波速）
    % 确保vs_edge为行向量
    %% ========================================================================
    vs_edge = vs_edge(:)';
    
    % 初始化输出向量（包含NaN占位）
    vs_mode_n0 = nan(dis, 1);
    
    % 处理dis=1的特殊情况
    if dis == 1
        return; % 直接返回NaN填充的向量
    end
    
    % 步骤1：构建模态解矩阵（标记置信密度最大的位置）
    mode = zeros(dis-1, dis_y-1);
    for i = 1:(dis-1)
        row = CI_density_limit(i, :);
        if ~any(isfinite(row) & row > 0)
            continue;
        end
        row(~isfinite(row)) = -Inf;
        [~, idx] = max(row);
        mode(i, idx) = 1;
    end
    
    % 步骤2：将模态解映射到实际Vs值
    vs_mode = zeros(dis-1, dis_y-1);
    for i = 1:(dis-1)
        vs_mode(i, :) = mode(i, :) .* vs_edge;
    end
    
    % 步骤3：提取非零值（即各深度的最佳Vs值）
    for i = 1:(dis-1)
        if any(mode(i, :))
            vs_mode_n0(i) = max(vs_mode(i, :));
        end
    end
    
    % 步骤4：边界扩展（将最后一个有效值复制到额外深度点）
    vs_mode_n0(dis) = vs_mode_n0(dis-1);
end
