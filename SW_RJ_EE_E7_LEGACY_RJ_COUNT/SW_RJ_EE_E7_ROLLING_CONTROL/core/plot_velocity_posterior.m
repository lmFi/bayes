function plot_velocity_posterior(priors, depth_grid, Model, vs_mode, ...
    best_model_vs, vs_mean, vs_median, vs_edge, depth_edge, ...
    posterior_density, result, variable)
%PLOT_VELOCITY_POSTERIOR Plot Vs profiles, posterior density and interfaces.

    blue = [0.137 0.357 0.651];
    orange = [0.890 0.290 0.200];
    green = [0.086 0.639 0.290];
    purple = [0.494 0.184 0.557];
    dark = [0.067 0.094 0.153];
    prior_gray = [0.40 0.45 0.53];

    fig = figure('Color', 'w', 'Name', 'Posterior Vs summary', ...
        'Position', [80 80 1420 680]);
    layout = tiledlayout(fig, 1, 5, ...
        'TileSpacing', 'compact', 'Padding', 'compact');

    depth_grid = depth_grid(:);
    vs_mode = vs_mode(:);
    best_model_vs = best_model_vs(:);
    vs_mean = vs_mean(:);
    vs_median = vs_median(:);
    prior_depth = priors.x(:);
    prior_min = priors.vsmin_profile(:);
    prior_max = priors.vsmax_profile(:);

    [~, true_interfaces] = true_model_metadata(Model);
    true_layer_count = (numel(Model) + 1) / 2;
    true_velocity = Model(1:true_layer_count);
    true_thickness = Model(true_layer_count + 1:end);
    true_depth_plot = [0, repelem(cumsum(true_thickness), 2), priors.depth_max];
    true_vs_plot = repelem(true_velocity, 2);

    %% (a) Velocity profiles and prior range
    ax1 = nexttile(layout, 1, [1 2]);
    hold(ax1, 'on');
    x_fill = [prior_min; flipud(prior_max)];
    y_fill = [prior_depth; flipud(prior_depth)];
    h_range = fill(ax1, x_fill, y_fill, [0.91 0.97 0.91], ...
        'FaceAlpha', 0.90, 'EdgeColor', 'none', ...
        'DisplayName', 'Prior search range');
    h_bounds = plot(ax1, prior_min, prior_depth, '--', ...
        'Color', prior_gray, 'LineWidth', 1.0, ...
        'DisplayName', 'Prior bounds');
    plot(ax1, prior_max, prior_depth, '--', ...
        'Color', prior_gray, 'LineWidth', 1.0, ...
        'HandleVisibility', 'off');
    h_true = plot(ax1, true_vs_plot, true_depth_plot, ...
        'Color', dark, 'LineWidth', 2.0, 'DisplayName', 'True model');
    h_best = plot(ax1, best_model_vs, depth_grid, ...
        'Color', orange, 'LineWidth', 1.7, ...
        'DisplayName', 'Best-fitting model');
    h_mode = plot(ax1, vs_mode, depth_grid, ...
        'Color', green, 'LineWidth', 1.6, ...
        'DisplayName', 'Posterior mode');
    h_mean = plot(ax1, vs_mean, depth_grid, ...
        'Color', purple, 'LineWidth', 1.6, ...
        'DisplayName', 'Posterior mean');
    h_median = plot(ax1, vs_median, depth_grid, ...
        'Color', blue, 'LineWidth', 1.7, ...
        'DisplayName', 'Posterior median');
    set(ax1, 'YDir', 'reverse');
    ylim(ax1, [0 priors.depth_max]);
    xlabel(ax1, 'Shear-wave velocity V_s (m/s)');
    ylabel(ax1, 'Depth (m)');
    title(ax1, '(a) Velocity profiles');
    style_axes(ax1, true);
    legend(ax1, [h_range h_bounds h_true h_best h_mode h_mean h_median], ...
        'Location', 'southoutside', 'NumColumns', 2, ...
        'FontSize', 9, 'Box', 'off');

    %% (b) Posterior density of Vs
    ax2 = nexttile(layout, 3, [1 2]);
    hold(ax2, 'on');
    pcolor(ax2, vs_edge, depth_edge, posterior_density);
    shading(ax2, 'interp');
    % colormap(ax2, posterior_blue_colormap(256));
    colormap('jet');
    caxis(ax2, [0 0.2]);
    h_true_density = plot(ax2, true_vs_plot, true_depth_plot, ...
        'Color', dark, 'LineWidth', 1.7, 'DisplayName', 'True model');
    % h_median_density = plot(ax2, vs_median, depth_grid, ...
    %     'Color', [0.976 0.451 0.086], 'LineWidth', 1.7, ...
    %     'DisplayName', 'Posterior median');
    set(ax2, 'YDir', 'reverse');
    ylim(ax2, [0 priors.depth_max]);
    xlabel(ax2, 'Shear-wave velocity V_s (m/s)');
    ylabel(ax2, 'Depth (m)');
    title(ax2, '(b) Posterior density of V_s');
    style_axes(ax2, false);
    % legend(ax2, [h_true_density h_median_density], ...
    %     'Location', 'southoutside', 'FontSize', 9, 'Box', 'off');
   legend(ax2, h_true_density, ...
    'Location', 'southoutside', 'FontSize', 9, 'Box', 'off');
    cb = colorbar(ax2);
    cb.Ticks = 0:0.04:0.20;
    cb.Label.String = 'Normalized posterior density';
    cb.Label.FontName = 'Times New Roman';
    cb.FontName = 'Times New Roman';

    %% (c) Posterior interface-depth density
    ax3 = nexttile(layout, 5);
    hold(ax3, 'on');
    if variable.counter_auxiliary > 0
        interface_samples = result.change_points(1:variable.counter_auxiliary);
        interface_samples = interface_samples(isfinite(interface_samples));
        depth_bin_width = 0.25;
        edges = 0:depth_bin_width:priors.depth_max;
        if edges(end) < priors.depth_max
            edges(end + 1) = priors.depth_max;
        end
        [pdf_value, edges] = histcounts(interface_samples, edges, ...
            'Normalization', 'pdf');
        centers = 0.5 * (edges(1:end-1) + edges(2:end));
        pdf_value = movmean(pdf_value, 3);
        plot(ax3, pdf_value, centers, 'Color', [0.36 0.17 0.17], ...
            'LineWidth', 2.0);
        max_pdf = max(pdf_value, [], 'omitnan');
        if isfinite(max_pdf) && max_pdf > 0
            xlim(ax3, [0 1.08 * max_pdf]);
        end
    end
    for i = 1:numel(true_interfaces)
        yline(ax3, true_interfaces(i), ':', ...
            'Color', [0.55 0.60 0.68], 'LineWidth', 0.9, ...
            'HandleVisibility', 'off');
    end
    set(ax3, 'YDir', 'reverse');
    ylim(ax3, [0 priors.depth_max]);
    xlabel(ax3, 'Interface probability density (m^{-1})');
    ylabel(ax3, 'Depth (m)');
    title(ax3, '(c) Interface probability');
    style_axes(ax3, true);

    title(layout, 'Posterior shear-wave velocity structure', ...
        'FontName', 'Times New Roman', 'FontSize', 16, ...
        'FontWeight', 'bold', 'Color', [0.09 0.15 0.33]);
end
