function plotLfpData(ex, lfp, figuresPath, filename, plotFun)
%plotSpikeData Plot spiking data with the given list of plotting functions

if iscell(plotFun)
    for i = 1:length(plotFun)
         plotLfpData(ex, lfp, figuresPath, filename, plotFun{i})
    end
    return;
end

% Per-electrode figures
for i = 1:length(lfp.electrodeid)

    if ~isempty(ex.RecordSession) && ~isempty(ex.RecordSite)
        exDir = sprintf('%s_%s',ex.RecordSession,ex.RecordSite);
    else
        exDir = sprintf('%s%s',ex.RecordSession,ex.RecordSite);
    end
    elecDir = sprintf('Ch%02d',lfp.electrodeid(i));
    fileDir = fullfile(figuresPath,exDir,elecDir);
    if ~isdir(fileDir)
        mkdir(fileDir)
    end

    nf = NeuroFig(ex.ID, lfp.electrodeid(i), []);
    nf = plotFun(nf, ex, lfp.data(:,i), lfp.fs, lfp.time);
    nf.print(fileDir, filename, 'png');
    nf.close();

end