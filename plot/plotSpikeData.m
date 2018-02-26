function plotSpikeData(ex, spike, figuresPath, filename, plotFun)
%plotSpikeData Plot spiking data with the given list of plotting functions

if iscell(plotFun)
    for i = 1:length(plotFun)
         plotSpikeData(ex, spike, figuresPath, filename, plotFun{i})
    end
    return;
end

% Do electrodes assigned
for i = 1:length(spike)
    uuid = spike(i).uuid;

    % Plotting Figures
    if ~isempty(ex.RecordSession) && ~isempty(ex.RecordSite)
        exDir = sprintf('%s_%s',ex.RecordSession,ex.RecordSite);
    else
        exDir = sprintf('%s%s',ex.RecordSession,ex.RecordSite);
    end
    elecDir = sprintf('Ch%02d',spike(i).electrodeid);
    if ~isdir(fullfile(figuresPath,exDir,elecDir))
        mkdir(fullfile(figuresPath,exDir,elecDir))
    end

    % Per-cell figures
    for j = 1:length(uuid)
        u = uuid(j);
        nf = plotFun(ex, spike(i), u);
        nf.print(fullfile(figuresPath,exDir,elecDir), filename, 'png');
        nf.close();    
    end
end