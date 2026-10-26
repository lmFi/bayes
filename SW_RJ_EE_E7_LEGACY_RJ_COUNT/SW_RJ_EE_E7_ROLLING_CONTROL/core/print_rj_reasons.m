function print_rj_reasons(Num)
    for t=1:numel(Num)
        fprintf('Chain %d RJ terminal outcomes:\n',t);
        for op={'birth','death'}
            total=0;
            fprintf('  %s:',op{1});
            for r={'limit','bounds','prior','forward','mh_reject','accepted','disabled'}
                n=Num(t).([op{1} '_' r{1}]); total=total+n;
                fprintf(' %s=%d',r{1},n);
            end
            fprintf('\n');
            if strcmp(op{1},'birth'), attempts=Num(t).PB; else, attempts=Num(t).PD; end
            assert(total==attempts,'RJ diagnostic counts must sum to attempts.');
        end
    end
end
