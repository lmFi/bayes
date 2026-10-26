function [num_layers, interface_depths] = true_model_metadata(Model)
%TRUE_MODEL_METADATA Return layer count and interface depths from Model.
% Model convention: [Vs_1 ... Vs_L, h_1 ... h_(L-1)].

    num_layers = (numel(Model) + 1) / 2;
    if abs(num_layers - round(num_layers)) > eps
        error('true_model_metadata:InvalidModel', ...
            'Model must contain L velocities followed by L-1 thicknesses.');
    end
    num_layers = round(num_layers);
    interface_depths = cumsum(Model(num_layers + 1:end));
end
