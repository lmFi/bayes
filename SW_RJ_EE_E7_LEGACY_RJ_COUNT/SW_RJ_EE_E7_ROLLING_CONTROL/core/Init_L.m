function [nuclei_vs,nuclei_depths,npt,priors_OK,like,forward_model] = ...
   Init_L(npt_init,priors,data_mode,fit_error,x)

% 创建深度相关的波速范围
if ~isfield(priors, 'vsmin_profile') || isempty(priors.vsmin_profile)
    % 计算速度梯度 (线性增长)
    depth_max = priors.depth_max;
    min_vs = priors.vsmin(1);
    max_vs = priors.vsmax(1);
    
    % 创建波速范围 - 浅层窄范围，深层宽范围
    vs_min_profile = min_vs + (max_vs - min_vs) * (x / depth_max).^0.5;
    vs_max_profile = min_vs + (max_vs - min_vs) * (x / depth_max).^0.7 * 1.3;
    
    % 确保不超过全局先验范围
    vs_min_profile = max(vs_min_profile, min_vs);
    vs_max_profile = min(vs_max_profile, max_vs);
else
    % 使用预先计算的深度相关波速范围
    vs_min_profile = priors.vsmin_profile;
    vs_max_profile = priors.vsmax_profile;
end

npt=npt_init;
nuclei_depths=zeros(priors.npt_max+priors.num_layers,1);
nuclei_vs = zeros(priors.npt_max+priors.num_layers,1);

for i = 1:priors.num_layers
    % 使用层中间位置作为固定核位置
    if i == 1
        layer_top = 0;
    else
        layer_top = priors.layer_depths(i-1);
    end
    
    if i < priors.num_layers
        layer_bottom = priors.layer_depths(i);
    else
        layer_bottom = priors.depth_max;
    end
    
    nuclei_depths(i) = (layer_top + layer_bottom) / 2;
    
    % 确定该深度的波速范围
    [~, idx] = min(abs(x - nuclei_depths(i)));
    vs_min = vs_min_profile(idx);
    vs_max = vs_max_profile(idx);
    
    % 生成该深度位置对应的波速
    nuclei_vs(i) = vs_min + rand() * (vs_max - vs_min);
end

% 初始化浮动核的位置和波速
for i = 1:npt
    % 在深度范围内随机选择位置
    depth = priors.depth_min + rand() * (priors.depth_max - priors.depth_min);
    
    % 确定该深度的波速范围
    [~, idx] = min(abs(x - depth));
    vs_min = vs_min_profile(idx);
    vs_max = vs_max_profile(idx);
    
    % 将浮动核位置添加到数组
    nuclei_depths(priors.num_layers + i) = depth;
    
    % 生成该深度位置对应的波速
    nuclei_vs(priors.num_layers + i) = vs_min + rand() * (vs_max - vs_min);
end

    [thickness, density, vp, vs, priors_OK] = thicknesses_and_priors(nuclei_depths, nuclei_vs, npt,  priors); 
 
    [forward_model, like] = forward_model_misfit( ...
        thickness, vp, vs, density, data_mode, fit_error);

