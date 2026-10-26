function [vs_median] = Depth_median_vs(dis, dis_y, CI_density_limit, vs_edge)
    % DEPTH_MEDIAN_VS - 计算各深度点的波速中位数（基于置信密度分布）
    %
    % 输入参数:
    %   dis                - 深度离散点数（垂直分辨率）
    %   dis_y              - 波速离散点数（水平分辨率）
    %   CI_density_limit   - 置信密度矩阵（归一化后）
    %   vs_edge            - 波速网格边界向量
    %
    % 输出参数:
    %   vs_median          - 各深度点的波速中位数
    % 初始化输出向量（dis个深度点）
    vs_median = nan(dis, 1);
    %% ========================================================================
    % 处理特殊情况：只有一个深度点
    if dis == 1
        return;
    end
    
    % 确保vs_edge是行向量
    vs_edge = vs_edge(:)';
    
    % 遍历每个深度点（1到dis-1）
    for i = 1:(dis-1)
        % 获取当前深度的置信密度分布
        weights = CI_density_limit(i, :);
        total_weight = sum(weights);
        
        % 检查有效权重
        if total_weight <= 0
            vs_median(i) = nan;
            continue;
        end
        
        % 计算累积分布函数（CDF）
        [sorted_vals, sort_idx] = sort(vs_edge);
        sorted_weights = weights(sort_idx);
        cdf = cumsum(sorted_weights)/total_weight;
        
        % 寻找中位数位置（累积概率≥0.5的第一个点）
        median_idx = find(cdf >= 0.5, 1, 'first');
        
        if isempty(median_idx)
            vs_median(i) = nan;
        else
            % 精确中位数计算（考虑线性插值）
            if median_idx == 1
                vs_median(i) = sorted_vals(1);
            else
                % 线性插值公式
                low_val = sorted_vals(median_idx-1);
                high_val = sorted_vals(median_idx);
                low_cdf = cdf(median_idx-1);
                high_cdf = cdf(median_idx);
                
                % 插值比例
                frac = (0.5 - low_cdf)/(high_cdf - low_cdf);
                vs_median(i) = low_val + frac*(high_val - low_val);
            end
        end
    end
    
    % 边界处理：最后一个深度点使用倒数第二个值
    vs_median(dis) = vs_median(dis-1);
end