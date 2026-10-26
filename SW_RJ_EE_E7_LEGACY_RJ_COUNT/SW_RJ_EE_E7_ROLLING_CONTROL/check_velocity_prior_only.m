function check_velocity_prior_only
% 只检查速度先验，不运行正演和MCMC

    clearvars
    close all
    clc

    root = fileparts(mfilename('fullpath'));
    addpath(root, '-begin');
    addpath(fullfile(root, 'core'), '-begin');

    cfg = rj_ee_options('five');

    % 构造最小先验结构
    priors.depth_min = cfg.depth_min;
    priors.depth_max = cfg.depth_max;
    priors.vsmin = cfg.vs_min;
    priors.vsmax = cfg.vs_max;

    % 深度网格
    x = linspace( ...
        cfg.depth_min, cfg.depth_max, cfg.dis).';

    % 与主程序完全一致的参考速度
    initial_model = linspace( ...
        cfg.vs_min, cfg.vs_max, cfg.dis).';

    % 计算比例先验
    priors = velocity_search_range( ...
        priors, x, cfg.search_range, ...
        'InitialModel', initial_model, ...
        'MinRatio', cfg.min_ratio, ...
        'MaxRatio', cfg.max_ratio);

    % 检查上下界
    assert(all(isfinite(priors.vsmin_profile)));
    assert(all(isfinite(priors.vsmax_profile)));
    assert(all(priors.vsmin_profile < ...
               priors.vsmax_profile));

    %% 绘图
    figure('Color', 'w');
    hold on

    % 绿色先验范围
    fill( ...
        [priors.vsmin_profile; ...
         flipud(priors.vsmax_profile)], ...
        [x; flipud(x)], ...
        [0.80 0.95 0.80], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.50, ...
        'DisplayName', 'Prior range');

    % 两条边界
    plot(priors.vsmin_profile, x, ...
        'b--', 'LineWidth', 2, ...
        'DisplayName', 'Prior lower bound');

    plot(priors.vsmax_profile, x, ...
        'r--', 'LineWidth', 2, ...
        'DisplayName', 'Prior upper bound');

    % 参考速度
    plot(initial_model, x, ...
        'k:', 'LineWidth', 1.5, ...
        'DisplayName', 'Reference profile');

    %% 绘制真实模型，仅用于合成实验检查
    [nLayer, interfaces] = true_model_metadata(cfg.Model);
    true_vs = cfg.Model(1:nLayer);

    true_depth = zeros(2*nLayer, 1);
    true_velocity = zeros(2*nLayer, 1);

    layer_top = cfg.depth_min;

    for k = 1:nLayer
        if k < nLayer
            layer_bottom = interfaces(k);
        else
            layer_bottom = cfg.depth_max;
        end

        ii = 2*k-1 : 2*k;

        true_depth(ii) = [layer_top; layer_bottom];
        true_velocity(ii) = true_vs(k);

        layer_top = layer_bottom;
    end

    plot(true_velocity, true_depth, ...
        'k-', 'LineWidth', 2.2, ...
        'DisplayName', 'True model');

    set(gca, ...
        'YDir', 'reverse', ...
        'FontSize', 12);

    xlabel('Shear-wave velocity Vs (m/s)');
    ylabel('Depth (m)');
    title(sprintf( ...
        'Velocity prior: min ratio %.2f, max ratio %.2f', ...
        cfg.min_ratio, cfg.max_ratio));

    grid on
    box on
    legend('Location', 'best');

    xlim([cfg.vs_min-50, cfg.vs_max+50]);
    ylim([cfg.depth_min, cfg.depth_max]);

    %% 输出几个深度的实际数值
    query_depth = unique([ ...
        0 5 10 15 20 25 30 cfg.depth_max]).';

    query_depth = query_depth( ...
        query_depth >= cfg.depth_min & ...
        query_depth <= cfg.depth_max);

    lower = interp1( ...
        x, priors.vsmin_profile, query_depth);

    upper = interp1( ...
        x, priors.vsmax_profile, query_depth);

    width = upper-lower;

    PriorTable = table( ...
        query_depth, lower, upper, width, ...
        'VariableNames', ...
        {'Depth_m','VsLower','VsUpper','Width'});

    disp(PriorTable);
end