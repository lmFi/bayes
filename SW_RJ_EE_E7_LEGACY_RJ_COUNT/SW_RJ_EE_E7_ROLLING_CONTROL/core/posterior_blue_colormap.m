function cmap = posterior_blue_colormap(n)
%POSTERIOR_BLUE_COLORMAP Sequential white-to-blue posterior-density map.
% Low probability is white and high probability is dark blue.  The map is
% monotonic in lightness and remains readable in slides and printouts.

    if nargin < 1 || isempty(n)
        n = 256;
    end

    anchors = [
        1.0000 1.0000 1.0000
        0.9098 0.9490 1.0000
        0.7216 0.8471 1.0000
        0.4039 0.6627 0.9373
        0.1451 0.3882 0.7804
        0.0392 0.1843 0.4196];
    anchor_x = linspace(0, 1, size(anchors, 1));
    query_x = linspace(0, 1, n);
    cmap = interp1(anchor_x, anchors, query_x, 'pchip');
    cmap = min(max(cmap, 0), 1);
end
