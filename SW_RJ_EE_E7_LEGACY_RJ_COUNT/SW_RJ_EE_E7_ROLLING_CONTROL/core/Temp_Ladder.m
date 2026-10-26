function beta = Temp_Ladder(T, Tmin, Tmax, method)
% TEMPLADDER 生成温度阶梯
%
%   beta = TEMPLADDER(T, Tmin, Tmax, method) 返回一个 1×T 逆温度向量，
%   支持两种阶梯类型：
%     'geometric' : 等比阶梯（对数空间均匀）
%     'linear'    : 线性阶梯（温度空间均匀）
%
% 输入参数：
%   T      – 链的数量 (整数，>=2)
%   Tmin   – 最低温度 (标量，>0)
%   Tmax   – 最高温度 (标量，>0)
%   method – 字符串，'geometric' 或 'linear'
%
% 输出参数：
%   beta   – 1×T 逆温度向量，beta = 1./Temp

    % 输入校验
    if T < 2
        error('T 必须大于等于 2。');
    end
    if Tmin <= 0 || Tmax <= 0
        error('Tmin 和 Tmax 必须为正数。');
    end

    % 生成温度阶梯
    switch lower(method)
        case 'geometric'
            r    = (Tmax / Tmin)^(1 / (T - 1));      % 公比
            Temp1 = Tmin * r .^ (0 : T-1);            % 等比分布
            beta = 1 ./ Temp1;
            % Temp = Temp1;
            disp('Geometric Ladder:');
            disp(Temp1);

        case 'linear'
            Temp1 = linspace(Tmin, Tmax, T);         % 等差分布
            beta = 1 ./ Temp1;
            disp('Linear Ladder:');
            disp(Temp1);

        otherwise
            error('method 必须为 ''geometric'' 或 ''linear''。');
    end
end
