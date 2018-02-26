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
    switch dataset.ex.ID
        case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                'NaturalImages', 'NaturalVideos', 'spontanous'}
            plotFun = {@plotRastergram, @plotPsth};
        case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
            plotFun = @plotMap;
        otherwise
            plotFun = {@plotRastergram, @plotPsth, @plotTuningCurve};
    end
end

ex = dataset.ex;
spike = dataset.spike;
[~, filename, ~] = fileparts(dataset.filepath);
if isParallel
    parfor i = 1:length(spike)
        plotSpikeData(ex, spike(i), figuresPath, filename, plotFun)
    end
else
    plotSpikeData(ex, spike, figuresPath, filename, plotFun);
end

end
