function index = whichnuclei(points, depth, priors)
% WHICHNUCLEI - 查找与指定深度相对应的最近核索引
%
% 此函数确定给定深度所在的层，并在该层内查找最近的核点
%
% 输入参数:
%   points - 所有核的位置数组（深度值）
%   depth  - 目标深度值
%   priors - 包含先验信息的结构体
%
% 输出参数:
%   index  - 距离目标深度最近的核索引
%
% 函数流程:
%   1. 确定目标深度所在的层
%   2. 确定该层的顶部和底部深度
%   3. 在该层内查找所有核点
%   4. 找到距离目标深度最近的核点

%% ========================================================================
%% 1. 确定目标深度所在的层
% 默认在最后一层
layer = priors.num_layers;

% 遍历所有层边界（除了最后一层）
for j = 1:(priors.num_layers - 1)
    % 检查深度是否小于当前层边界
    if depth <= priors.layer_depths(j)
        layer = j;  % 深度位于第j层
        break;      % 找到后跳出循环
    end
end

%% ========================================================================
%% 2. 确定该层的顶部和底部深度
if layer == 1
    % 第一层处理
    if priors.num_layers == 1
        % 单层模型：整个深度范围
        top_of_layer = priors.depth_min;
        bottom_of_layer = priors.depth_max;
    else
        % 多层模型的第一层
        top_of_layer = priors.depth_min;
        bottom_of_layer = priors.layer_depths(1);
    end
elseif layer < priors.num_layers
    % 中间层处理
    top_of_layer = priors.layer_depths(layer-1);
    bottom_of_layer = priors.layer_depths(layer);
else
    % 最后一层处理
    top_of_layer = priors.layer_depths(layer-1);
    bottom_of_layer = priors.depth_max;
end

%% ========================================================================
%% 3. 在该层内查找所有核点
% 找出位于当前层内的所有核点
% 条件：核深度 >= 层顶部 且 < 层底部
indices = find((points >= top_of_layer) & (points < bottom_of_layer));

%% ========================================================================
%% 4. 找到距离目标深度最近的核点
if isempty(indices)
    % 如果当前层内没有核点，则在整个点集中查找最近点
    [~, index] = min(abs(depth - points));
else
    % 计算目标深度与层内各核点的距离
    distances = abs(depth - points(indices));
    
    % 找到最小距离的索引
    [~, min_idx] = min(distances);
    
    % 获取全局索引
    index = indices(min_idx);
end
end