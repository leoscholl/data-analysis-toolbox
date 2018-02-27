function [result] = dispatch(dataset, figuresPath, isParallel, ...
    spikeFormat, plotFun)
%dispatch Send dataset to the appropriate plotting/analysis functions

if nargin < 5
    plotFun = [];
end
if nargin < 4
    spikeFormat = [];
end
if nargin < 3 || isempty(isParallel)
    isParallel = false;
end

result = [];

if iscell(dataset) 
    if length(dataset) == 1
        dataset = dataset{1};
    elseif isParallel
        parfor i = 1:length(dataset)
            dispatch(dataset{i}, figuresPath, false);
        end
        return;
    else
        for i = 1:length(dataset)
            dispatch(dataset{i}, figuresPath, false);
        end
        return;
    end
end

if ischar(dataset)
    % Need to load from file
    dataset = loadDataset(dataset, spikeFormat);
end

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
        nConds = length(fieldnames(dataset.ex.CondTestCond));
        if nConds > 1
            plotFun = @plotMap;
        elseif nConds == 1
            plotFun = {@plotRastergram, @plotPsth, @plotTuningCurve};
        else
            plotFun  = {@plotRastergram, @plotPsth};
        end
    end
end

% Separate to spikes and lfp
lfpFunList = {'plotLfp'};
isLfpFun = cellfun(@(x)ismember(func2str(x), lfpFunList), plotFun);
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
