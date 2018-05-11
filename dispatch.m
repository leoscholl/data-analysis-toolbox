function [result] = dispatch(dataset, figuresPath, isParallel, plotFun)
%dispatch Send dataset to the appropriate plotting/analysis functions

if nargin < 4
    plotFun = [];
end
if nargin < 3 || isempty(isParallel)
    isParallel = false;
end

result = [];

% What to plot?
if isempty(plotFun)
    if strcmp(dataset.ex.sourceformat, 'VisStim')
        switch dataset.ex.ID
            case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                    'NaturalImages', 'NaturalVideos', 'spontanous'}
                plotFun = {@plotRastergram, @plotPsth};
            case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                plotFun = @plotMap;
            otherwise
                plotFun = {@plotRastergram, @plotPsth, @plotTuningCurve};
        end
    else
        if contains(dataset.ex.ID, 'RF')
            plotFun = {@plotMap};
        else
            plotFun = {@plotRastergram, @plotTuningCurve};
        end
        if strcmp(dataset.ex.ID, 'Image') || strcmp(dataset.ex.ID, 'LaserImage')
            return;
        end
    end
end

% Separate to spikes and lfp
isLfpFun = cellfun(@(x)contains(lower(func2str(x)), 'lfp'), plotFun);
spikeFun = plotFun(~isLfpFun);
lfpFun = plotFun(isLfpFun);

% Dispatch to plotting functions
dataset.ex.secondperunit = dataset.secondperunit;
[~, filename, ~] = fileparts(dataset.filepath);
if isParallel
    spike = dataset.spike;
    ex = dataset.ex;
    parfor i = 1:length(spike)
        plotSpikeData(ex, spike(i), figuresPath, filename, spikeFun);
    end
else
    plotSpikeData(dataset.ex, dataset.spike, figuresPath, filename, spikeFun);
end
plotLfpData(dataset.ex, dataset.lfp, figuresPath, filename, lfpFun);


end
