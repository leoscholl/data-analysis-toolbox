function [result] = dispatch(dataset, figuresPath, isParallel, plotFun, varargin)
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
                plotFun = {'plotRastergram', 'plotPsth'};
            case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                plotFun = {'plotMap'};
            otherwise
                plotFun = {'plotRastergram', 'plotPsth', 'plotTuningCurve'};
        end
    else
        if contains(dataset.ex.ID, 'RF')
            plotFun = {'plotMap'};
        else
            plotFun = {'plotRastergram', 'plotTuningCurve'};
        end
        if strcmp(dataset.ex.ID, 'Image') || strcmp(dataset.ex.ID, 'LaserImage')
            return;
        end
    end
end

% Dispatch to plotting functions
result = processData(dataset, figuresPath, plotFun, isParallel, varargin{:});

end
