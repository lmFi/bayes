function variable = initialize_variable(dis, num) %#ok<INUSD>
%INITIALIZE_VARIABLE Initialize retained-sample counters.
% Posterior profiles are stored once in result.vs_all, so the former
% dis-by-num MINI/MAXI caches are intentionally no longer allocated.

    variable.counter_basic = 0;
    variable.counter_auxiliary = 0;
end
