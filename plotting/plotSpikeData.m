function plotSpikeData(figuresPath, fileName, Results,...
    plotFun, whichElectrodes, showFigures, isparallel)
%plotAllResults Function plotting Tuning Curves for different stimuli

% Check arguments
narginchk(4,7);
if isempty(Results)
    warning('Cannot plot results without results...');
    return; % Can't do anything.
end

if nargin < 7 || isempty(isparallel)
    isparallel = true;
end
if nargin < 6 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 5 || isempty(whichElectrodes)
    whichElectrodes = [Results.spike.electrodeid];
end
if showFigures; showFigures = 'on'; else; showFigures = 'off'; end

% Set up broadcast variables
Params = Results.Params;
spike = Results.spike;

% Go through each electrode
if isparallel
    
    % Start the parallel pool if one isn't already opened
    if length(whichElectrodes) > 1 && isempty(gcp('nocreate'))
        parpool; % start the parallel pool
    end
    
    parfor i = 1:length(whichElectrodes)
        elecNo = spike(i).electrodeid;
        if ~ismember(elecNo, whichElectrodes)
            continue;
        end
        
        SpikeData = spike(i).Data;
        Statistics = spike(i).Statistics;
        
        if isempty(SpikeData) || isempty(Statistics)
            continue;
        end
        
        plotSingle(SpikeData, Statistics, Params, elecNo, ...
            figuresPath, fileName, plotFun, showFigures);
        
    end % Electrodes loop
else
    for i = 1:length(whichElectrodes)
        elecNo = spike(i).electrodeid;
        if ~ismember(elecNo, whichElectrodes)
            continue;
        end
        
        SpikeData = spike(i).Data;
        Statistics = spike(i).Statistics;
        
        if isempty(SpikeData) || isempty(Statistics)
            continue;
        end
        
        plotSingle(SpikeData, Statistics, Params, elecNo, ...
            figuresPath, fileName, plotFun, showFigures);
    end
end

end


function plotSingle(SpikeData, Statistics, Params, elecNo, ...
    figuresPath, fileName, plotFun, showFigures)

if iscell(plotFun)
    for i = 1:length(plotFun)
        plotSingle(SpikeData, Statistics, Params, elecNo, ...
            figuresPath, fileName, plotFun{i}, showFigures)
    end
    return;
end

cells = unique(SpikeData.cell);
cellColors = makeDefaultColors(cells);

% Plotting Figures
elecDir = sprintf('Ch%02d',elecNo);
if ~isdir(fullfile(figuresPath,elecDir))
    mkdir(fullfile(figuresPath,elecDir))
end

% Per-cell figures
for j = 1:length(cells)
    u = cells(j);
    
    % TC plots
    figBaseName = [fileName,'_',num2str(u),'El',num2str(elecNo)];
    
    StatsUnit = Statistics(Statistics.cell == u,:);
    SpikeDataUnit = SpikeData(SpikeData.cell == u,:);
    
    [handles, suffix] = plotFun(StatsUnit, SpikeDataUnit, ...
        Params, cellColors(j,:), showFigures, elecNo, u);
    
    if ~iscell(handles)
        handles = {handles};
        suffix = {suffix};
    end
    
    for h = 1:length(handles)
        saveas(handles{h},fullfile(figuresPath,elecDir,[figBaseName,'_',suffix{h},'.png']));
        close(handles{h});
    end
    
    
end
end