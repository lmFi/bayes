function [nuclei_depths, nuclei_vs, npt, like] = swap_pair(nuclei_depths, nuclei_vs, npt, like, i, j)
% SWAP_PAIR 交换第 i、j 条温度链的状态
    nuclei_depths(:, [i, j]) = nuclei_depths(:, [j, i]);
    nuclei_vs(:,      [i, j]) = nuclei_vs(:,      [j, i]);
    npt([i, j])               = npt([j, i]);
    like([i, j])              = like([j, i]);
end