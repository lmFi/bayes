function [p_birth, p_death, p_move] = rj_operation_probabilities(npt, priors)
%RJ_OPERATION_PROBABILITIES Conditional proposal probabilities on odd steps.

    probabilities = [1/3, 1/3, 1/3];
    names = {'proposal_prob_birth', 'proposal_prob_death', 'proposal_prob_move'};
    for k = 1:3
        if isfield(priors, names{k}) && ~isempty(priors.(names{k}))
            value = priors.(names{k});
            if isa(value, 'function_handle')
                value = value(npt, priors);
            end
            probabilities(k) = value;
        end
    end
    if any(~isfinite(probabilities) | probabilities <= 0)
        error('rj_operation_probabilities:InvalidProbability', ...
            'Birth, death and move proposal probabilities must be positive.');
    end
    probabilities = probabilities / sum(probabilities);
    p_birth = probabilities(1);
    p_death = probabilities(2);
    p_move = probabilities(3);
end
