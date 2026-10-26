%% ========================================================================
function [pos_hist, rt_count, rt_mean_swaps, rt_mean_iters] = compute_roundtrips(pos_hist_in, T, swap_interval)
% pos_hist_in: [nEvents x T]，列=replica编号，值=该replica所在链位置(1..T)
% round-trip 定义：1 -> T -> 1 的完整往返（以"回到1"为一次完成）

    pos_hist = pos_hist_in;
    nE = size(pos_hist, 1);
    rt_count = zeros(1, T);
    rt_mean_swaps = nan(1, T);
    rt_mean_iters = nan(1, T);

    for r = 1:T
        p = pos_hist(:, r);

        trips = 0;
        durations = [];

        k = 1;
        while k <= nE
            % 找到下一次到达冷端 1 的时间
            k1 = find(p(k:end) == 1, 1, 'first');
            if isempty(k1), break; end
            k1 = k1 + k - 1;

            % 找到从 k1 之后第一次到达热端 T
            kT = find(p(k1:end) == T, 1, 'first');
            if isempty(kT), break; end
            kT = kT + k1 - 1;

            % 找到从 kT 之后第一次回到冷端 1（完成一次 round-trip）
            k1b = find(p(kT:end) == 1, 1, 'first');
            if isempty(k1b), break; end
            k1b = k1b + kT - 1;

            trips = trips + 1;
            durations(end+1) = (k1b - k1); %#ok<AGROW>

            % 下一次从 k1b 之后继续找
            k = k1b + 1;
        end

        rt_count(r) = trips;
        if ~isempty(durations)
            rt_mean_swaps(r) = mean(durations);
            rt_mean_iters(r) = mean(durations) * swap_interval;
        end
    end
end