%% ========================================================================
%% 参数相关性与后验PDF曲线图（修复数组大小问题）
function plot_parameter_correlation_from_inversion(result, priors, x)
% PLOT_PARAMETER_CORRELATION_FROM_INVERSION - 从反演结果绘制参数相关性与后验PDF曲线图
%
% 输入参数:
%   result  - 反演结果结构体
%   priors  - 先验信息结构体
%   x       - 深度网格向量
%
% 输出: 参数相关性与后验PDF曲线图

%% ========================================================================
%% 参数准备
% 获取后验样本
if isfield(result, 'vs_all_sampled')
    posterior_samples = result.vs_all_sampled;  % 使用采样后的样本
else
    posterior_samples = result.vs_all;  % 所有样本的波速剖面
end

% 选择关键深度点（基于反演结果）
depth_points = [5, 10, 15,25];  % 选择5个关键深度点

% 修复数组大小问题：确保深度点与深度网格兼容
depth_indices = zeros(1, length(depth_points));
for i = 1:length(depth_points)
    [~, depth_indices(i)] = min(abs(x - depth_points(i)));
end

param_names = arrayfun(@(d) sprintf('Vs at %d m', d), depth_points, 'UniformOutput', false);

% 提取选定深度点的波速样本
selected_samples = posterior_samples(:, depth_indices);

%% ========================================================================
%% 创建图形
figure('color', 'w', 'Position', [100, 100, 600, 600]);
t = tiledlayout(length(depth_points), length(depth_points), ...
    'TileSpacing', 'tight', 'Padding', 'tight');

%% ========================================================================
%% 主循环绘制每个子图
for row = 1:length(depth_points)
    for col = 1:length(depth_points)
        % 创建当前子图
        ax = nexttile((row-1)*length(depth_points) + col);
        hold(ax, 'on');
        
        % 对角线图：参数PDF曲线
        if row == col
            plot_parameter_pdf(ax, selected_samples(:, row), param_names{row});
            
        % 非对角线图：参数相关性散点图
        else
            plot_parameter_scatter(ax, selected_samples(:, col), ...
                                   selected_samples(:, row), ...
                                   param_names{col}, param_names{row});
        end
    end
end

%% ========================================================================
%% 添加整体标题
annotation('textbox', [0.1 0.95 0.8 0.05], ...
           'String', 'Parameter Correlation and Posterior PDF (Based on Inversion Results)', ...
           'HorizontalAlignment', 'center', ...
           'VerticalAlignment', 'middle', ...
           'EdgeColor', 'none', ...
           'FontSize', 14, ...
           'FontWeight', 'bold');

%% ========================================================================
%% 添加坐标轴标签
% X轴标签（最下面一行）
for i = 1:length(depth_points)
    ax_x = nexttile((length(depth_points)-1)*length(depth_points) + i);
    if i == round(length(depth_points)/2)
        xlabel(ax_x, ['Vs at ', num2str(depth_points(i)), ' m'], ...
               'FontSize', 12, 'FontWeight', 'bold');
    end
end

% Y轴标签（最左边一列）
for i = 1:length(depth_points)
    ax_y = nexttile((i-1)*length(depth_points) + 1);
    if i == round(length(depth_points)/2)
        ylabel(ax_y, ['Vs at ', num2str(depth_points(i)), ' m'], ...
               'FontSize', 12, 'FontWeight', 'bold');
    end
end

%% ========================================================================
%% 保存图片
saveas(gcf, 'inversion_parameter_correlation.png');
end

%% ========================================================================
%% 子函数：绘制参数PDF曲线
function plot_parameter_pdf(ax, data, param_name)
% 计算KDE概率密度
[pdf_values, x_values] = ksdensity(data);

% 绘制PDF曲线
plot(ax, x_values, pdf_values, 'b-', 'LineWidth', 1.5);

% 计算并填充68%置信区间
[sorted_pdf, idx] = sort(pdf_values, 'descend');
cum_prob = cumsum(sorted_pdf)/sum(sorted_pdf);
ci_idx = idx(cum_prob <= 0.68);
fill(ax, x_values(ci_idx), pdf_values(ci_idx), 'b', ...
     'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 设置图形属性
ax.XGrid = 'on';
ax.YGrid = 'on';
ax.Box = 'on';
ax.XTick = [];
ax.YTick = [];
title(ax, '', 'FontSize', 12);
end

%% ========================================================================
%% 子函数：绘制参数相关性散点图
function plot_parameter_scatter(ax, x_data, y_data, x_name, y_name)
% 计算相关性系数
r = corr(x_data, y_data, 'rows', 'complete');

% 创建半透明散点图
scatter(ax, x_data, y_data, 15, ...
        'MarkerFaceColor', [0.1 0.8 0.1], ...  % 绿色
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.2);

% 添加回归线和方程
valid_idx = isfinite(x_data) & isfinite(y_data);
if sum(valid_idx) > 1
    p = polyfit(x_data(valid_idx), y_data(valid_idx), 1);
    x_range = linspace(min(x_data(valid_idx)), max(x_data(valid_idx)), 100);
    y_fit = polyval(p, x_range);
    plot(ax, x_range, y_fit, 'r-', 'LineWidth', 1.5);
end

% 添加相关系数文本
if isfinite(r)
    text(ax, min(x_data), max(y_data), ...
         sprintf('r = %.2f', r), ...
         'VerticalAlignment', 'top', ...
         'HorizontalAlignment', 'left', ...
         'FontSize', 10, ...
         'BackgroundColor', 'white');
end

% 设置图形属性
ax.XGrid = 'on';
ax.YGrid = 'on';
ax.Box = 'on';
ax.XTick = [];
ax.YTick = [];
end