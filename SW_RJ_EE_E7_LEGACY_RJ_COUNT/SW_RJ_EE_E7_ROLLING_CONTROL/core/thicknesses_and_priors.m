function [thickness, layer_density, layer_vp, layer_vs, priors_OK] = ...
    thicknesses_and_priors(nuclei_positions_unsorted, nuclei_vs, num_floating_nuclei, priors)
% THICKNESSES_AND_PRIORS - 将Voronoi核描述转换为层状模型参数，并检查先验条件
%
% 此函数执行两个主要功能：
%   1. 检查模型参数是否符合先验约束条件
%   2. 将Voronoi核描述转换为层状模型参数（厚度、密度、波速）
%
% 输入参数:
%   nuclei_positions_unsorted - 未排序的核位置数组（深度）
%   nuclei_vs                 - 对应的横波速度数组
%   num_floating_nuclei       - 浮动核的数量
%   priors                    - 包含先验信息的结构体
%
% 输出参数:
%   thickness      - 各层的厚度数组
%   layer_density  - 各层的密度数组
%   layer_vp       - 各层的纵波速度数组
%   layer_vs       - 各层的横波速度数组
%   priors_OK      - 标志位(1=符合先验条件, 0=不符合)
%
% 函数流程:
%   1. 初始化输出参数和标志位
%   2. 检查浮动核数量是否在允许范围内
%   3. 检查多层模型中的核位置
%   4. 合并固定层和浮动层核，并排序
%   5. 计算纵波速度和密度
%   6. 检查各层速度是否符合先验范围
%   7. 检查深度范围
%   8. 计算各层厚度

%% ========================================================================
%% 1. 初始化参数和标志位
priors_OK = 1;  % 初始化为符合先验条件
thickness = zeros(1, num_floating_nuclei + priors.num_layers); % 预分配厚度数组
layer_density = [];
layer_vp = [];
layer_vs = [];

%% ========================================================================
%% 2. 检查浮动核数量是否在允许范围内
if num_floating_nuclei < priors.npt_min || num_floating_nuclei > priors.npt_max
    priors_OK = 0; 
    return; % 提前返回
end

%% ========================================================================
%% 3. 检查多层模型中的核位置（仅当层数>1时）
if priors.num_layers > 1
    for i = 1:priors.num_layers
        % 确定当前层的顶部和底部深度
        if i == 1
            top_of_layer = priors.depth_min;
            bottom_of_layer = priors.layer_depths(1);
        elseif i < priors.num_layers
            top_of_layer = priors.layer_depths(i-1);
            bottom_of_layer = priors.layer_depths(i);
        else
            top_of_layer = priors.layer_depths(i-1);
            bottom_of_layer = priors.depth_max;
        end
        
        % 检查固定层核位置是否在层边界内
        if nuclei_positions_unsorted(i) < top_of_layer || ...
           nuclei_positions_unsorted(i) > bottom_of_layer
            priors_OK = 0;
            return; % 提前返回
        end
    end
end

%% ========================================================================
%% 4. 合并固定层和浮动层核，并排序
% 提取所有核位置（固定层+浮动层）
all_nuclei_positions = nuclei_positions_unsorted(1:num_floating_nuclei + priors.num_layers);

% 对核位置进行排序
[nuclei_positions, I] = sort(all_nuclei_positions);

% 根据排序索引重新排列横波速度
layer_vs = nuclei_vs(I);

%% ========================================================================
%% 5. 计算纵波速度和密度

%% ========================================================================
%% 5. 计算纵波速度和密度（按 priors.vp_density_mode 二选一）

% mode = lower(string(priors.vp_density_mode));
% if mode == "empirical"
%     layer_vp = priors.vp .* ones(length(layer_vs),1);
%     layer_density = priors.density .* ones(length(layer_vs),1);
% 
% elseif mode == "prior"
%     layer_vp = priors.vp_vs .* layer_vs;
%     % Gardner (1987): rho(g/cc)=0.31*Vp(m/s)^0.25
%     layer_density = 0.31 .* (layer_vp .^ 0.25);
% else
%     error("priors.vp_density_mode 只能为 'empirical' 或 'prior'，当前为: %s", mode);
% end


% 使用经验公式（给定priors.vp_vs）计算
layer_vp = priors.vp_vs .* layer_vs;
 % layer_density = 0.31 .* layer_vp.^(0.25);
 layer_density = 0.31 .* layer_vp.^(0.25);
% layer_density = 2 * ones(size(layer_vp));
% 使用先验priors.vp和priors.density计算
% layer_vp = 1440.*ones(length(layer_vs),1);
% layer_density = 1.85.*ones(length(layer_vs),1);

% layer_vp = 663.*ones(length(layer_vs),1);
% layer_density = 1.6.*ones(length(layer_vs),1);
%% ========================================================================
% %% 6. 检查各层速度是否符合先验范围
% for i = 1:(num_floating_nuclei + priors.num_layers)
%     % 确定当前核所在的层
%     layer = priors.num_layers; % 默认在最后一层
%     for j = 1:(priors.num_layers - 1)
%         if nuclei_positions(i) <= priors.layer_depths(j)
%             layer = j;
%             break;
%         end
%     end
% 
%     % 检查速度是否在允许范围内
%     if layer_vs(i) < priors.vsmin(layer) || layer_vs(i) > priors.vsmax(layer)
%         priors_OK = 0;
%         return; % 提前返回
%     end
% end
%----------------
for i = 1:(num_floating_nuclei + priors.num_layers)

    % 1) 若存在深度相关 profile，就用它
    if isfield(priors,'vsmin_profile') && ~isempty(priors.vsmin_profile) && ...
       isfield(priors,'vsmax_profile') && ~isempty(priors.vsmax_profile) && ...
       isfield(priors,'x') && ~isempty(priors.x)

        [~, depth_idx] = min(abs(priors.x - nuclei_positions(i)));
        vmin_i = priors.vsmin_profile(depth_idx);
        vmax_i = priors.vsmax_profile(depth_idx);

        if layer_vs(i) < vmin_i || layer_vs(i) > vmax_i
            priors_OK = 0; return;
        end

    else
        % 2) 否则退回到按层常数范围
        layer = priors.num_layers;
        for j = 1:(priors.num_layers - 1)
            if nuclei_positions(i) <= priors.layer_depths(j)
                layer = j; break;
            end
        end

        if layer_vs(i) < priors.vsmin(layer) || layer_vs(i) > priors.vsmax(layer)
            priors_OK = 0; return;
        end
    end
end
%% 6. 检查各层速度是否符合"全局硬约束"（不再使用 profile）
% K = num_floating_nuclei + priors.num_layers;
% 
% % 允许你在主程序显式指定 vsmin_hard/vsmax_hard；否则退回 vsmin(1)/vsmax(1)
% if isfield(priors,'vsmin_hard') && ~isempty(priors.vsmin_hard)
%     vmin = priors.vsmin_hard;
% else
%     vmin = priors.vsmin(1);
% end
% 
% if isfield(priors,'vsmax_hard') && ~isempty(priors.vsmax_hard)
%     vmax = priors.vsmax_hard;
% else
%     vmax = priors.vsmax(1);
% end
% 
% % 对 nuclei 的 Vs 做硬约束检查（也可换成 layer_vs(:)）
% if any(layer_vs(1:K) < vmin) || any(layer_vs(1:K) > vmax)
%     priors_OK = 0;
%     return;
% end

%% ========================================================================
%% 7. 检查深度范围
if max(nuclei_positions) > priors.depth_max || min(nuclei_positions) < priors.depth_min
    priors_OK = 0;
    return; % 提前返回
end

%% ========================================================================
%% 8. 计算各层厚度
starting_index = 1; % 厚度数组起始索引

% 遍历每一层
for layer = 1:priors.num_layers
    % 确定当前层内的核索引
    if priors.num_layers == 1
        % 单层模型：所有核都在同一层
        layer_indices = 1:(num_floating_nuclei + priors.num_layers);
        top_of_layer = 0;
    else
        if layer == 1
            % 第一层：深度小于第一个边界
            layer_indices = find(nuclei_positions < priors.layer_depths(layer));
            top_of_layer = 0;
        elseif layer < priors.num_layers
            % 中间层：深度在两个边界之间
            layer_indices = find(nuclei_positions > priors.layer_depths(layer-1) & ...
                                 nuclei_positions < priors.layer_depths(layer));
            top_of_layer = priors.layer_depths(layer-1);
        else
            % 最后一层：深度大于最后一个边界
            layer_indices = find(nuclei_positions > priors.layer_depths(layer-1));
            top_of_layer = priors.layer_depths(layer-1);
        end
    end
    
    % 获取当前层的核位置
    layer_nuclei = nuclei_positions(layer_indices);
    num_in_layer = length(layer_indices);
    
    % 处理当前层中的核
    if num_in_layer == 1
        % 单核层处理
        if layer == 1
            if priors.num_layers == 1
                thickness(starting_index) = 0; % 单层单核模型
            else
                thickness(starting_index) = priors.layer_depths(1); % 第一层单核
            end
        elseif layer < priors.num_layers
            thickness(starting_index) = priors.layer_depths(layer) - priors.layer_depths(layer-1); % 中间层单核
        else
            thickness(starting_index) = 0; % 最后一层单核（半空间）
        end
        starting_index = starting_index + 1;
    else
        % 多核层处理
        % 第一个子层厚度：从层顶到前两个核的中点
        thickness(starting_index) = 0.5 * (layer_nuclei(1) + layer_nuclei(2)) - top_of_layer;
        
        % 中间子层厚度：相邻核的中点之间
        for i = 2:(num_in_layer - 1)
            thickness(starting_index + i - 1) = 0.5 * (layer_nuclei(i+1) + layer_nuclei(i)) - ...
                                               0.5 * (layer_nuclei(i) + layer_nuclei(i-1));
        end
        
        % 最后一个子层厚度
        if layer == priors.num_layers
            % 最后一层：最后两个核中点到层底（半空间厚度为0）
            thickness(starting_index + num_in_layer - 1) = 0;
        else
            % 中间层：最后两个核中点到下一层边界
            last_mid = 0.5 * (layer_nuclei(end) + layer_nuclei(end-1));
            thickness(starting_index + num_in_layer - 1) = priors.layer_depths(layer) - last_mid;
        end
        
        % 更新起始索引
        starting_index = starting_index + num_in_layer;
    end
end

end % 函数结束