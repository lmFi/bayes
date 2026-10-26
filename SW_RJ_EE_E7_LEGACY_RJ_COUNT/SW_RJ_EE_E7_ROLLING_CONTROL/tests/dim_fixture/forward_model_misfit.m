function [forward_model, like] = forward_model_misfit(thickness,vp,vs,density,data_mode,fit_error) %#ok<INUSD>
% Test-only replacement, deliberately guarded against real inversion data.
    if ~isfield(data_mode,'dim_test_only') || ~data_mode.dim_test_only
        error('DIM:TestOnly','This fixture must never run on real data.');
    end
    calculated=mean(vs)*ones(size(data_mode.freq));
    forward_model=[data_mode.freq calculated];
    like=0.5*sum(((calculated-data_mode.data_mode)./fit_error.fitting_error).^2);
end
