function test_plotting_helpers
%TEST_PLOTTING_HELPERS Verify non-graphical plotting support functions.

    cmap = posterior_blue_colormap(256);
    assert(isequal(size(cmap), [256, 3]));
    assert(all(isfinite(cmap(:))));
    assert(all(cmap(:) >= 0 & cmap(:) <= 1));
    assert(norm(cmap(1, :) - [1 1 1]) < 1e-12);
    assert(mean(cmap(end, :)) < mean(cmap(1, :)));

    Model = [400 600 500 700 900 5 5 5 10];
    [num_layers, interfaces] = true_model_metadata(Model);
    assert(num_layers == 5);
    assert(isequal(interfaces, [5 10 15 25]));

    fprintf('  PASS: plotting helpers and true-model metadata\n');
end
