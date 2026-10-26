function [swap_prop,swap_acc,Temp_history, swap_ratio_history] = initialize_history(nsample, T,Temp)
% INITIALIZE_HISTORY 初始化历史记录数据结构
% 为温度历史和交换接受率历史预分配空间
swap_prop = zeros(T-1, 1);      % proposed 次数
swap_acc  = zeros(T-1, 1);      % accepted 次数  
Temp_history = zeros(nsample, T);
Temp_history(1, :) = Temp;
swap_ratio_history = nan(nsample, 1);  % 每次迭代的平均交换接受率（相邻温度对平均）
end