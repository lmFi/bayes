function fixed_data=Filter_Local_median(data,window_size,thresh_ratio,min_diff)

% 参数设置
%window_size = 21;      % 移动窗口大小（奇数）
%thresh_ratio = 0.01;   % 差值与中值的比例阈值
%min_diff = 0.05;        % 最小绝对差值阈值

% 初始化修复后的数据
fixed_data = data;
n = length(data);

for i = 1:n
    % 确定滑动窗口范围
    start_idx = max(1, i - floor(window_size/2));
    end_idx = min(n, i + floor(window_size/2));
    window = data(start_idx:end_idx);
    
    % 计算窗口中值
    med = median(window);
    
    % 计算当前值与中值的绝对差值
    diff_val = abs(data(i) - med);
    
    % 双重判断条件检测异常
    if (diff_val > min_diff) && (diff_val > thresh_ratio * med)
        % 基于相邻有效值线性插值修复
        prev_val = med;
        next_val = med;
        
        % 查找前一个有效值
        for j = i-1:-1:1
            diff_j = abs(data(j) - med);
            if (diff_j <= min_diff) || (diff_j <= thresh_ratio * med)
                prev_val = data(j);
                break;
            end
        end
        
        % 查找后一个有效值
        for j = i+1:n
            diff_j = abs(data(j) - med);
            if (diff_j <= min_diff) || (diff_j <= thresh_ratio * med)
                next_val = data(j);
                break;
            end
        end
        
        % 使用前后有效值的平均值进行修复
        fixed_data(i) = (prev_val + next_val)/2;
    end
end

% % % 标注修复点
% repaired_idx = find(data ~= fixed_data);
% 
% % 打印修复统计
% fprintf('共修复 %d 个异常点 (%.2f%%)\n', length(repaired_idx), length(repaired_idx)/n*100);

end