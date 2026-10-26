function [data_mode, data, raw_table] = read_dispersion_modes(filename)
%READ_DISPERSION_MODES
% 读取带有 Freq_Hz、Mode0、Mode1、Mode3 等表头的频散数据。
%
% 支持：
%
%   Freq_Hz    Mode0
%   Freq_Hz    Mode0    Mode1
%   Freq_Hz    Mode0    Mode3
%   Freq_Hz    Mode1    Mode2    Mode4
%
% 模态列不要求连续，也不要求输入时已经排序。
%
% 输出：
%   data_mode.freq
%   data_mode.data_mode
%   data_mode.mode_indices
%   data_mode.mode_names
%   data_mode.dc_num
%   data_mode.nd
%
% 示例：
%
%   [data_mode, data] = read_dispersion_modes('Line_Q_01.txt');
%
% 对于表头：
%
%   Freq_Hz    Mode0    Mode3
%
% 返回：
%
%   data_mode.mode_indices = [0 3]
%   data_mode.data_mode(:,1) 对应 Mode0
%   data_mode.data_mode(:,2) 对应 Mode3

    if nargin < 1 || isempty(filename)
        error('read_dispersion_modes:MissingFilename', ...
            '必须提供频散数据文件名。');
    end

    if ~isfile(filename)
        error('read_dispersion_modes:FileNotFound', ...
            '找不到频散数据文件：%s', filename);
    end

%% ========================================================================
% 1. 读取表格并保留原始变量名
% ========================================================================

    try
        raw_table = readtable( ...
            filename, ...
            'FileType', 'text', ...
            'VariableNamingRule', 'preserve');
    catch ME
        error('read_dispersion_modes:ReadFailed', ...
            '无法读取文件：%s\n%s', filename, ME.message);
    end

    if isempty(raw_table) || height(raw_table) < 1
        error('read_dispersion_modes:EmptyFile', ...
            '频散数据文件为空：%s', filename);
    end

    variable_names = string(raw_table.Properties.VariableNames);

%% ========================================================================
% 2. 识别频率列
% ========================================================================

    normalized_names = lower( ...
        regexprep(variable_names, '[^a-zA-Z0-9]', ''));

    frequency_aliases = [ ...
        "freqhz", ...
        "frequencyhz", ...
        "freq", ...
        "frequency"];

    frequency_column = find( ...
        ismember(normalized_names, frequency_aliases), ...
        1, 'first');

    if isempty(frequency_column)
        error('read_dispersion_modes:MissingFrequencyColumn', ...
            ['没有找到频率列。频率列表头应为 Freq_Hz、Freq、' ...
             'Frequency_Hz 或 Frequency。']);
    end

%% ========================================================================
% 3. 识别 ModeN 列
% ========================================================================

    mode_columns = [];
    mode_indices = [];

    for column_index = 1:numel(variable_names)

        if column_index == frequency_column
            continue;
        end

        current_name = char(strtrim(variable_names(column_index)));

        token = regexpi( ...
            current_name, ...
            '^\s*Mode[\s_\-]*(\d+)\s*$', ...
            'tokens', ...
            'once');

        if isempty(token)
            continue;
        end

        mode_number = str2double(token{1});

        if ~isfinite(mode_number) || ...
                mode_number < 0 || ...
                mode_number ~= round(mode_number)
            continue;
        end

        mode_columns(end + 1) = column_index; %#ok<AGROW>
        mode_indices(end + 1) = mode_number; %#ok<AGROW>
    end

    if isempty(mode_columns)
        error('read_dispersion_modes:MissingModeColumns', ...
            ['没有找到 ModeN 形式的频散列。' ...
             '例如：Mode0、Mode1、Mode3。']);
    end

    if numel(unique(mode_indices)) ~= numel(mode_indices)
        error('read_dispersion_modes:DuplicateModes', ...
            '文件中存在重复的模态列。');
    end

%% ========================================================================
% 4. 按物理模态编号排序
% ========================================================================

    [mode_indices, sort_order] = sort(mode_indices);
    mode_columns = mode_columns(sort_order);

%% ========================================================================
% 5. 转换为数值矩阵
% ========================================================================

    frequency = local_column_to_double( ...
        raw_table{:, frequency_column});

    observed = nan(height(raw_table), numel(mode_columns));

    for mode_column = 1:numel(mode_columns)
        observed(:, mode_column) = local_column_to_double( ...
            raw_table{:, mode_columns(mode_column)});
    end

%% ========================================================================
% 6. 删除非法频率行
% ========================================================================

    valid_frequency = isfinite(frequency) & frequency > 0;

    if ~all(valid_frequency)
        warning('read_dispersion_modes:InvalidFrequencyRows', ...
            '删除了 %d 行非有限或非正频率数据。', ...
            sum(~valid_frequency));

        frequency = frequency(valid_frequency);
        observed = observed(valid_frequency, :);
    end

    if isempty(frequency)
        error('read_dispersion_modes:NoValidFrequency', ...
            '文件中没有有效的正频率数据。');
    end

%% ========================================================================
% 7. 删除完全没有数据的模态列
% ========================================================================

    mode_has_data = any(isfinite(observed), 1);

    if any(~mode_has_data)
        empty_modes = mode_indices(~mode_has_data);

        warning('read_dispersion_modes:EmptyModes', ...
            '删除完全为空的模态列：%s', ...
            sprintf('Mode%d ', empty_modes));

        observed = observed(:, mode_has_data);
        mode_indices = mode_indices(mode_has_data);
    end

    if isempty(mode_indices)
        error('read_dispersion_modes:NoObservedModes', ...
            '没有包含有限相速度值的模态列。');
    end

%% ========================================================================
% 8. 构建 data_mode
% ========================================================================

    data_mode = struct();

    data_mode.freq = frequency(:);
    data_mode.data_mode = observed;

    % 真实 disba 物理模态编号。
    data_mode.mode_indices = mode_indices(:).';

    % 便于绘图和输出。
    data_mode.mode_names = arrayfun( ...
        @(mode_number) sprintf('Mode%d', mode_number), ...
        data_mode.mode_indices, ...
        'UniformOutput', false);

    % dc_num 是实际输入模态列数，不是最大模态编号加一。
    data_mode.dc_num = size(observed, 2);
    data_mode.nd = numel(frequency);

    data_mode.source_file = filename;

    % 保留与旧程序兼容的纯数值矩阵。
    data = [data_mode.freq, data_mode.data_mode];

%% ========================================================================
% 9. 输出读取信息
% ========================================================================

    fprintf('\n读取频散数据：%s\n', filename);
    fprintf('频率点数：%d\n', data_mode.nd);
    fprintf('识别模态：');

    for mode_column = 1:data_mode.dc_num
        current_mode = data_mode.mode_indices(mode_column);
        current_count = sum(isfinite( ...
            data_mode.data_mode(:, mode_column)));

        fprintf(' Mode%d(N=%d)', current_mode, current_count);
    end

    fprintf('\n');
end


function values = local_column_to_double(column_data)
%LOCAL_COLUMN_TO_DOUBLE 将 table 列转换为 double 列向量。

    if isnumeric(column_data) || islogical(column_data)
        values = double(column_data);
    elseif iscell(column_data)
        values = str2double(string(column_data));
    elseif isstring(column_data) || ischar(column_data) || ...
            iscategorical(column_data)
        values = str2double(string(column_data));
    else
        values = str2double(string(column_data));
    end

    values = values(:);
end