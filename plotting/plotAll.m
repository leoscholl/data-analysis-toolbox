function plotAll(figuresPath, fileName, Results,...
    whichElectrodes, showFigures, isparallel)
%plotAll Function plotting Tuning Curves for different stimuli

% Check arguments
narginchk(3,6);
if isempty(Results)
    warning('Cannot plot results without results...');
    return; % Can't do anything.
end

if nargin < 6 || isempty(isparallel)
    isparallel = true;
end
if nargin < 5 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 4 || isempty(whichElectrodes)
    whichElectrodes = [Results.spike.electrodeid];
end

% What to plot?
plotFun = {};
stimType = Results.Params.stimType;
switch stimType
    case {'LatencyTest', 'LaserON', 'LaserGratings', ...
            'NaturalImages', 'NaturalVideos', 'spontanous'}
        plotFun = {@plotBarGraph, @plotRastergrams};
    case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
        plotFun = @plotMap;
    otherwise
        plotFun = {@plotRasters, @plotTCurve};

        if contains(fileName,'R') && (contains(stimType,'Temporal') || ...
            contains(stimType,'Spatial'))
            plotFun = [plotFun, {@plotVelTCurve}];
        end
end

plotSpikeData(figuresPath, fileName, Results,...
    plotFun, whichElectrodes, showFigures, isparallel)

end
