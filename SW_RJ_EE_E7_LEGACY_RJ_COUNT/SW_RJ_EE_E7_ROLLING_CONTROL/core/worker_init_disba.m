function worker_init_disba(corePath)
% 在每个 worker 上执行：路径 + 环境变量 + disba 初始化（无对象池）

    addpath(corePath);

    % 避免"多进程 × 多线程"过载（强烈建议）
    setenv('OMP_NUM_THREADS','1');
    setenv('MKL_NUM_THREADS','1');
    setenv('OPENBLAS_NUM_THREADS','1');
    setenv('NUMEXPR_NUM_THREADS','1');
    setenv('NUMBA_NUM_THREADS','1');

    % 每个 worker 独立 numba cache，避免并发写冲突
    setenv('NUMBA_CACHE_DIR', fullfile(tempdir, sprintf('numba_cache_%d', feature('getpid'))));

    % 初始化 disba（幂等，重复执行也没问题）
    initialize_disba;
end
