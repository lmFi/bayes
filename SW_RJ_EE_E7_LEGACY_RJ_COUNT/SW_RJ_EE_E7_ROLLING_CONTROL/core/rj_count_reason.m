function Num=rj_count_reason(Num,operation,reason)
% Mutually exclusive terminal outcomes per attempted Birth/Death.
    field=[operation '_' reason];
    if ~isfield(Num,field), Num.(field)=0; end
    Num.(field)=Num.(field)+1;
end
