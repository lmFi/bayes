function [result, best_model_vs] = Average_confidence(result, variable, priors, dis, best_mode, x)
    % AVERAGE_CONFIDENCE - 计算反演结果的最终平均模型和最佳模型
    %
    % 输入参数:
    %   result      - 结果结构体（包含累积的平均值）
    %   variable    - 变量跟踪结构体（包含样本计数器）
    %   priors      - 先验信息结构体
    %   dis         - 深度离散点数（垂直分辨率）
    %   best_mode   - 最佳模型信息（包含最佳层的深度和速度）
    %   x           - 深度网格向量
    %
    % 输出参数:
    %   result          - 更新后的结果结构体（包含最终平均模型）
    %   best_model_vs   - 最佳模型在深度网格上的波速值

    %% ========================================================================
    %% 计算最终平均模型
    
    retained_count = variable.counter_basic;
    if retained_count < 1
        error('Average_confidence:NoRetainedSamples', ...
            '没有可用于后处理的保留样本。请检查 burn-in、nsample 和 thin。');
    end

    % 通过除以实际保留样本数量完成平均计算
    result.AV = result.AV ./ retained_count;
    
    % 将平均值中的零值替换为NaN（标记无效数据点）
    result.AV(result.AV == 0) = nan;

    % 直接从冷链保留剖面计算逐深度 95%% 等尾可信区间。该结果不依赖
    % 密度图分箱、平滑或极值缓存，可直接用于论文绘图和数值报告。
    retained_vs = result.vs_all(1:retained_count, :);
    credible_interval = quantile(retained_vs, [0.025, 0.975], 1);
    result.vs_lower = credible_interval(1, :);
    result.vs_upper = credible_interval(2, :);

    %% ========================================================================
    %% 生成最佳模型的速度剖面
    
    % 预分配最佳模型速度数组
    best_model_vs = zeros(1, dis);
    
    % 遍历所有深度点
    for i = 1:dis
        %% 确定当前深度点对应的最佳层索引
        % 注意：仅考虑最佳模型中包含的层
        total_layers_best = priors.num_layers + best_mode.npt_best;
        depths_best = best_mode.depths_best(1:total_layers_best);
        
        %% 查找当前深度点对应的层
        ind = whichnuclei(depths_best, x(i), priors);
        
        %% 获取当前深度点的最佳波速值
        best_model_vs(i) = best_mode.vs_best(ind);
    end
end
