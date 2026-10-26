function visualize_search_range(priors)
% VISUALIZE_SEARCH_RANGE - 可视化横波速度搜索范围
%
% 输入参数:
%   priors - 包含搜索范围信息的先验结构体

% 创建新图形
figure;
set(gcf, 'color', 'w');
hold on;

% 获取深度网格
x = priors.x;

% 绘制初始模型
plot(priors.initial_vs_profile, x, 'k-', 'LineWidth', 2, 'DisplayName', '初始模型');

% 绘制搜索范围边界
plot(priors.vsmin_profile, x, 'b--', 'LineWidth', 1.5, 'DisplayName', '最小边界');
plot(priors.vsmax_profile, x, 'r--', 'LineWidth', 1.5, 'DisplayName', '最大边界');

% 创建填充区域
x_fill = [priors.vsmin_profile; flipud(priors.vsmax_profile)];
y_fill = [x; flipud(x)];

% 检查尺寸匹配
if length(x_fill) ~= length(y_fill)
    error('尺寸不匹配: 速度(%d) ≠ 深度(%d)', length(x_fill), length(y_fill));
end

% 填充搜索范围
fill(x_fill, y_fill, 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '搜索范围');

% 设置图形属性
set(gca, 'YDir', 'reverse', 'FontSize', 12);
title(sprintf('横波速度搜索范围 (%s模式)', priors.search_range.option), 'FontSize', 14);
xlabel('横波速度 (m/s)', 'FontSize', 12);
ylabel('深度 (m)', 'FontSize', 12);
legend('show', 'Location', 'southeast');
grid on;

% 添加信息框
annotation('textbox', [0.65, 0.15, 0.25, 0.1], 'String', ...
    {sprintf('模式: %s', priors.search_range.option), ...
     sprintf('最小比例: %.1f', priors.search_range.min_ratio), ...
     sprintf('最大比例: %.1f', priors.search_range.max_ratio)}, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', 'FontSize', 10);
end