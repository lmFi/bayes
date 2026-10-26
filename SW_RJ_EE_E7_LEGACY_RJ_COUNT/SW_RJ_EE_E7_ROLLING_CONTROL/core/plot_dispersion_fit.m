function plot_dispersion_fit(data_mode, forward_model_best)
%PLOT_DISPERSION_FIT Plot observations and the best-model prediction.
% Black circles are observations used by the likelihood.  The solid blue
% curve is the prediction over each mode's observed frequency interval;
% dashed light-blue segments are extrapolations outside that interval.

    blue = [0.137 0.357 0.651];
    pale_blue = [0.45 0.64 0.84];
    dark = [0.067 0.094 0.153];

    frequency = data_mode.freq(:);
    observed = data_mode.data_mode;
    prediction = forward_model_best(:, 2:end);
    n_modes = min(size(observed, 2), size(prediction, 2));

    if isfield(data_mode, 'mode_indices') && ...
            numel(data_mode.mode_indices) >= n_modes
        mode_indices = data_mode.mode_indices(1:n_modes);
    else
        mode_indices = 0:(n_modes - 1);
    end

    fig = figure('Color', 'w', 'Name', 'Dispersion-curve fit', ...
        'Position', [120 100 1080 680]);
    ax = axes(fig);
    hold(ax, 'on');

    h_observed = gobjects(1);
    h_prediction = gobjects(1);
    h_extrapolation = gobjects(1);

    for j = 1:n_modes
        obs_j = observed(:, j);
        pred_j = prediction(:, j);
        obs_valid = isfinite(obs_j);
        pred_valid = isfinite(pred_j);

        if ~any(obs_valid)
            continue;
        end

        f_observed = frequency(obs_valid);
        f_min = min(f_observed);
        f_max = max(f_observed);
        inside = pred_valid & frequency >= f_min & frequency <= f_max;
        outside_low = pred_valid & frequency < f_min;
        outside_high = pred_valid & frequency > f_max;

        if any(inside)
            h_line = plot(ax, frequency(inside), pred_j(inside), ...
                '-', 'Color', blue, 'LineWidth', 2.0);
            if ~isgraphics(h_prediction)
                h_prediction = h_line;
                h_prediction.DisplayName = ...
                    'Prediction from best-fitting sampled model';
            else
                h_line.HandleVisibility = 'off';
            end
        end

        extrapolation_masks = {outside_low, outside_high};
        for k = 1:numel(extrapolation_masks)
            mask = extrapolation_masks{k};
            if any(mask)
                h_extra = plot(ax, frequency(mask), pred_j(mask), ...
                    '--', 'Color', pale_blue, 'LineWidth', 1.5);
                if ~isgraphics(h_extrapolation)
                    h_extrapolation = h_extra;
                    h_extrapolation.DisplayName = ...
                        'Prediction outside observed frequency range';
                else
                    h_extra.HandleVisibility = 'off';
                end
            end
        end

        h_points = scatter(ax, frequency(obs_valid), obs_j(obs_valid), ...
            27, 'o', 'MarkerFaceColor', dark, 'MarkerEdgeColor', 'w', ...
            'LineWidth', 0.45);
        if ~isgraphics(h_observed)
            h_observed = h_points;
            h_observed.DisplayName = 'Observed dispersion data';
        else
            h_points.HandleVisibility = 'off';
        end

        last_index = find(obs_valid, 1, 'last');
        label_y = obs_j(last_index);
        if isfinite(pred_j(last_index))
            label_y = pred_j(last_index);
        end
        text(ax, frequency(last_index), label_y, ...
            sprintf('  Mode %d', mode_indices(j)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', [0.20 0.25 0.33], ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom');
    end

    xlabel(ax, 'Frequency (Hz)');
    ylabel(ax, 'Phase velocity (m/s)');
    title(ax, 'Multi-mode Rayleigh-wave dispersion fit', ...
        'FontWeight', 'bold', 'Color', [0.09 0.15 0.33]);
    style_axes(ax, true);

    handles = [h_observed h_prediction h_extrapolation];
    handles = handles(isgraphics(handles));
    if ~isempty(handles)
        legend(ax, handles, 'Location', 'best', ...
            'FontSize', 10, 'Box', 'on');
    end
end
