function out=forward_failure_log(action,detail)
% Counts only; first exception is retained without changing the likelihood.
    persistent stats
    if isempty(stats) || strcmp(action,'reset')
        stats=struct('calls',0,'bad_sigma',0,'wrong_length',0, ...
            'missing_prediction',0,'nonfinite_loss',0,'exception',0, ...
            'first_exception','');
    end
    if isfield(stats,action) && ~strcmp(action,'first_exception')
        stats.(action)=stats.(action)+1;
        if strcmp(action,'exception') && nargin>1 && isempty(stats.first_exception)
            stats.first_exception=detail;
        end
    end
    out=stats;
end
