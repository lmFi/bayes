function priors = velocity_search_range(priors, x, option, varargin)
% SETUP_VELOCITY_SEARCH_RANGE - 设置横波速度搜索范围
%
% 此函数根据选项设置横波速度搜索范围，支持两种模式：
%   1. 不使用深度递增搜索范围 - 在整个深度使用固定搜索范围
%   2. 使用深度递增搜索范围 - 基于初始模型设置深度相关的搜索范围
%
% 输入参数:
%   priors  - 先验信息结构体
%   x       - 深度网格向量 (列向量)
%   option  - 搜索范围选项 ('fixed' 或 'increasing')
%   varargin - 可选参数:
%       'InitialModel'    - 用户提供的初始模型 (与深度网格尺寸相同的向量)
%       'MinRatio'        - 最小比例系数 (默认0.5)
%       'MaxRatio'        - 最大比例系数 (默认1.5)
%
% 输出参数:
%   priors - 更新后的先验信息结构体，包含搜索范围信息

%% 参数验证
if nargin < 3
    error('需要至少三个输入参数: priors, x, option');
end

% 确保深度网格是列向量
if isrow(x)
    x = x';
end

% 检查选项有效性
validOptions = {'fixed', 'increasing'};
if ~any(strcmpi(option, validOptions))
    error('无效选项 "%s"。可用选项: "fixed" 或 "increasing"', option);
end

%% 设置默认参数
min_ratio = 0.5;
max_ratio = 1.5;
initial_vs_profile = [];

% 解析可选参数
for i = 1:2:length(varargin)
    param = varargin{i};
    value = varargin{i+1};
    
    switch lower(param)
        case 'initialmodel'
            if numel(value) ~= numel(x)
                error('初始模型尺寸与深度网格不匹配. 尺寸: 模型=%d, 网格=%d', numel(value), numel(x));
            end
            initial_vs_profile = value(:); % 确保是列向量
            
        case 'minratio'
            if ~isscalar(value) || value <= 0
                error('最小比例系数必须是正标量');
            end
            min_ratio = value;
            
        case 'maxratio'
            if ~isscalar(value) || value <= 0
                error('最大比例系数必须是正标量');
            end
            max_ratio = value;
            
        otherwise
            warning('忽略未知参数: %s', param);
    end
end

%% 存储深度网格
priors.x = x;  % 存储深度网格

%% 创建初始模型（如未提供）
if isempty(initial_vs_profile)
    % 默认线性初始模型
    initial_vs_min = priors.vsmin(1);
    initial_vs_max = priors.vsmax(1);
    
    % 计算初始深度位置权重
    depth_weights = (x - min(x)) / (max(x) - min(x));
    depth_weights = depth_weights .^ 0.7; % 非线性变换
    
    % 创建非线性初始模型
    initial_vs_profile = initial_vs_min + (initial_vs_max - initial_vs_min) * depth_weights;
end

% 存储初始模型
priors.initial_vs_profile = initial_vs_profile;

%% 设置搜索范围
switch lower(option)
    case 'fixed'
        % 固定搜索范围 - 整个深度使用相同的搜索范围
        priors.vsmin_profile = repmat(priors.vsmin(1), size(x)) * min_ratio;
        priors.vsmax_profile = repmat(priors.vsmax(1), size(x)) * max_ratio;
        
    case 'increasing'
        % 深度递增搜索范围
        priors.vsmin_profile = initial_vs_profile * min_ratio;
        priors.vsmax_profile = initial_vs_profile * max_ratio;
end

% 确保不超过全局先验范围
priors.vsmin_profile = max(priors.vsmin_profile, priors.vsmin(1));
priors.vsmax_profile = min(priors.vsmax_profile, priors.vsmax(1));

% 确保所有向量是列向量
vector_fields = {'vsmin_profile', 'vsmax_profile', 'initial_vs_profile'};
for i = 1:length(vector_fields)
    field = vector_fields{i};
    if isrow(priors.(field))
        priors.(field) = priors.(field)';
    end
end

%% 添加搜索范围信息
priors.search_range.option = option;
priors.search_range.min_ratio = min_ratio;
priors.search_range.max_ratio = max_ratio;
end