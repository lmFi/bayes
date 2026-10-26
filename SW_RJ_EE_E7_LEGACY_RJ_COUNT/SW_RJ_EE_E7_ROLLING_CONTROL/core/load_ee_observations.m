function [data,data_mode,fit_error]=load_ee_observations(cfg)
% Numeric file: frequency followed by mode velocities. NaN = no data.
    data=readmatrix(cfg.data_file,'FileType','text');
    data=data(~all(isnan(data),2),:);
    if size(data,2)<2 || isempty(data) || any(~isfinite(data(:,1)) | data(:,1)<=0)
        error('Data:Format','Expected positive frequency followed by mode velocities.');
    end
    if numel(unique(data(:,1)))~=size(data,1), error('Data:Frequency','Duplicate frequencies.'); end
    modes=cfg.mode_indices(:).';
    if isempty(modes), modes=0:size(data,2)-2; end
    if numel(modes)~=size(data,2)-1 || numel(unique(modes))~=numel(modes) || ...
            any(~isfinite(modes) | modes<0 | modes~=round(modes))
        error('Data:Modes','Specify one distinct nonnegative integer per mode column.');
    end
    obs=data(:,2:end);
    if any(isinf(obs(:))) || any(obs(isfinite(obs))<=0) || ~any(isfinite(obs(:)))
        error('Data:Velocity','Observed velocities must be positive or NaN.');
    end
    data_mode=struct('freq',data(:,1),'data_mode',obs,'nd',size(data,1), ...
        'dc_num',size(obs,2),'mode_indices',modes);
    fit_error.fitting_error=max(abs(obs)*cfg.relative_error,cfg.error_floor);
end
