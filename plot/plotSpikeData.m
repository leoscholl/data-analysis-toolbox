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
    fileDir = fullfile(figuresPath,exDir,elecDir);
    if ~isdir(fileDir)
        mkdir(fileDir)
    end

    % Per-electrode figures
    if ismember(func2str(plotFun), {'plotWaveforms'})
        nf = NeuroFig(ex.ID, spike(i).electrodeid, []);
        nf = plotFun(nf, ex, spike(i));
        nf.print(fileDir, filename, 'png');
        nf.close();
        continue;
    end
    
    % Per-cell figures
    for j = 1:length(uuid)
        spikes = spike(i).time(spike(i).unitid == uuid(j));
        if ~isempty(spikes)
            nf = NeuroFig(ex.ID, spike(i).electrodeid, uuid(j));
            nf = plotFun(nf, ex, spikes, uuid(j));
            nf.print(fileDir, filename, 'png');
            nf.close();
        end
    end
end