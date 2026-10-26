function [forward_model, like_prop] = forward_model_misfit( ...
    thickness, vp, vs, density, data_mode, fit_error)
%FORWARD_MODEL_MISFIT
% 计算指定物理模态的 Rayleigh 波频散曲线及高斯数据失配。
%
% 支持非连续模态输入，例如：
%
%   Freq_Hz    Mode0    Mode3
%
% 此时：
%
%   data_mode.mode_indices = [0, 3];
%
% forward_model 的列结构仍然采用紧凑格式：
%
%   第1列：频率
%   第2列：Mode0 理论相速度
%   第3列：Mode3 理论相速度
%
% 注意：
%   forward_model 的列数由"实际输入的模态数"决定，
%   而不是由 max(mode_indices)+1 决定。
%
% 输入：
%   thickness              层厚，单位 m
%   vp                     P 波速度，单位 m/s
%   vs                     S 波速度，单位 m/s
%   density                密度，单位 g/cm^3
%   data_mode.freq         频率向量
%   data_mode.data_mode    观测相速度矩阵
%   data_mode.mode_indices 真实物理模态编号，例如 [0 3]
%   fit_error.fitting_error
%
% 输出：
%   forward_model          [频率, 各指定模态的理论相速度]
%   like_prop              负对数似然中的数据失配项
%
% 当正演失败、理论值缺失或误差参数非法时，返回 Inf。

%% ========================================================================
% 1. 基本尺寸
% ========================================================================

    frequency = data_mode.freq(:);
    observed_all = data_mode.data_mode;

    num_frequency = numel(frequency);
    num_modes = size(observed_all, 2);

    if size(observed_all, 1) ~= num_frequency
        error('forward_model_misfit:DataSizeMismatch', ...
            ['data_mode.data_mode 的行数必须与 data_mode.freq 的长度一致。' ...
             '当前频率数为 %d，数据行数为 %d。'], ...
            num_frequency, size(observed_all, 1));
    end

    if ~isfield(fit_error, 'fitting_error') || ...
            ~isequal(size(fit_error.fitting_error), size(observed_all))
        error('forward_model_misfit:ErrorSizeMismatch', ...
            'fit_error.fitting_error 必须与 data_mode.data_mode 尺寸一致。');
    end

%% ========================================================================
% 2. 获取真实物理模态编号
% ========================================================================

    if isfield(data_mode, 'mode_indices') && ...
            ~isempty(data_mode.mode_indices)

        mode_indices = double(data_mode.mode_indices(:).');

    else
        % 向后兼容旧数据。
        %
        % 对于旧版没有 mode_indices 字段的结果，仍按连续模态解释：
        %
        % 第1个数据列 -> Mode0
        % 第2个数据列 -> Mode1
        % 第3个数据列 -> Mode2
        mode_indices = 0:(num_modes - 1);
    end

    if numel(mode_indices) ~= num_modes
        error('forward_model_misfit:ModeCountMismatch', ...
            ['data_mode.mode_indices 的元素数必须等于观测模态列数。' ...
             '当前 mode_indices 有 %d 个元素，观测数据有 %d 列。'], ...
            numel(mode_indices), num_modes);
    end

    if any(~isfinite(mode_indices)) || ...
            any(mode_indices < 0) || ...
            any(mode_indices ~= round(mode_indices))
        error('forward_model_misfit:InvalidModeIndices', ...
            '模态编号必须是有限的非负整数，例如 [0 1 2] 或 [0 3]。');
    end

    if numel(unique(mode_indices)) ~= numel(mode_indices)
        error('forward_model_misfit:DuplicateModeIndices', ...
            'data_mode.mode_indices 中存在重复模态编号。');
    end

%% ========================================================================
% 3. 初始化输出
% ========================================================================

    forward_model = nan(num_frequency, num_modes + 1);
    forward_model(:, 1) = frequency;

    like_prop = Inf;

%% ========================================================================
% 4. disba 正演
% ========================================================================

    forward_failure_log('calls');
    try
        % MATLAB 单位 m、m/s 转换为 disba 使用的 km、km/s。
        thickness_py = py.numpy.array(thickness(:).' ./ 1000);
        vp_py        = py.numpy.array(vp(:).'        ./ 1000);
        vs_py        = py.numpy.array(vs(:).'        ./ 1000);
        density_py   = py.numpy.array(density(:).');

        pd = py.disba.PhaseDispersion( ...
            thickness_py, vp_py, vs_py, density_py, ...
            pyargs( ...
                'algorithm', 'dunkin', ...
                'dc', 0.005));

        frequency_row = frequency.';
        periods = sort(1 ./ frequency_row);
        periods_py = py.numpy.array(periods);

        like_prop = 0;

%% ========================================================================
% 5. 按真实物理模态逐列计算
% ========================================================================

        for mode_column = 1:num_modes

            % 这里不是 mode_column-1，而是输入文件表头对应的真实模态号。
            physical_mode = mode_indices(mode_column);

            observed = observed_all(:, mode_column);
            sigma = fit_error.fitting_error(:, mode_column);

            observed_present = isfinite(observed);

            % 整列无观测数据时不参与失配计算。
            if ~any(observed_present)
                continue;
            end

            % 有观测数据的位置必须有合法误差。
            if any(observed_present & ...
                    (~isfinite(sigma) | sigma <= 0))
                forward_failure_log('bad_sigma');
                like_prop = Inf;
                return;
            end

            % 计算该物理模态。
            result = PhaseDispersion( ...
                pd, ...
                frequency_row, ...
                periods_py, ...
                physical_mode, ...
                'rayleigh');

            calculated = result.velocity(:);

            if numel(calculated) ~= num_frequency
                forward_failure_log('wrong_length');
                like_prop = Inf;
                return;
            end

            % 紧凑存储：
            % 第 mode_column+1 列对应 mode_indices(mode_column)。
            forward_model(:, mode_column + 1) = calculated;

            observed_mask = observed_present & ...
                            isfinite(sigma) & ...
                            sigma > 0;

            % 在有观测的位置，理论频散不得缺失。
            if any(observed_mask & ~isfinite(calculated))
                forward_failure_log('missing_prediction');
                like_prop = Inf;
                return;
            end

            residual = ...
                (observed(observed_mask) - calculated(observed_mask)) ./ ...
                sigma(observed_mask);

            like_prop = like_prop + 0.5 * sum(residual.^2);
        end

        if ~isfinite(like_prop)
            forward_failure_log('nonfinite_loss');
            like_prop = Inf;
        end

    catch ME
        forward_failure_log('exception',ME.message);
        % MCMC 中正演失败直接判定当前模型无效。
        % 不在这里频繁 warning，以免大量无效模型导致命令行刷屏。
        like_prop = Inf;
    end
end
