function [noise]=Gaussian_noise(disp_curve)

% disp_curve = data(:,2);  % 色散曲线数据
% 计算标准差
sigma_b = 8;  % 单位：m s^-1
a = 0.01;
sigma = sigma_b + a * (1:length(disp_curve))';

% 构建协方差矩阵
r = 0.7;
C = zeros(length(disp_curve));
for i = 1:length(disp_curve)
    for j = 1:length(disp_curve)
         C(i, j) = sigma(i) * sigma(j) * r^abs(i - j);
    end
end

% Cholesky 分解
L = chol(C, 'lower');

% 生成高斯随机向量
G = randn(length(disp_curve), 1);

% 生成相关噪声
N = L * G;

% 添加噪声
noisy_disp_curve = disp_curve + N;
noise=abs(noisy_disp_curve-disp_curve);