function b = ee_dim_bin(energy, edges)
%EE_DIM_BIN Same [lower,upper) convention for storage and retrieval.
    validateattributes(energy,{'numeric'},{'scalar','real','finite'});
    if isempty(edges), error('EE:DIMNoEdges','Energy boundaries are unavailable.'); end
    b=find(energy < edges(2:end),1,'first');
    if isempty(b), b=numel(edges)-1; end
end
