function edges = ee_edges_for_chain(EE, chain)
% Archive row j uses the partition for recipient j-1. Row 1 is diagnostic.
% Fallback supports old saved results and the original DIM contract tests.
    if isfield(EE,'chain_edges') && numel(EE.chain_edges)>=chain && ...
            ~isempty(EE.chain_edges{chain})
        edges=EE.chain_edges{chain};
    else
        edges=EE.edges;
    end
end
