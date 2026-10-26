
function [Num] = monitoring(T)

for i = 1:T
Num(i).AB=0;Num(i).AD=0;Num(i).PB=0;Num(i).PD=0;Num(i).AcV=0;Num(i).PV=0;Num(i).AP=0;Num(i).PP=0;
end

for t=1:numel(Num)
    for label={'birth','death'}
        for reason={'limit','bounds','prior','forward','mh_reject','accepted','disabled'}
            Num(t).([label{1} '_' reason{1}])=0;
        end
    end
end
end