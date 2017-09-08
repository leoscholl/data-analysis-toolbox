function [ handle, suffix ] = plotRastersAll(Statistics, SpikeData, ...
    Params, color, showFigure, elecNo, cell)
%PlotRasters opens and draws raster plot and PSTH figures
%   hRaster - handle for rater plot
%   hPSTH - handle for PSTH

% Truncate any long histograms to the same length
unpadded = SpikeData.hist;
lengths = cellfun('length',unpadded);
minSize = min(lengths);
Condition = Params.ConditionTable(find(cellfun('length',Params.ConditionTable.centers) == minSize, 1),:);
hists = [];
for k = 1:size(unpadded,1)
    hists{k,1} = unpadded{k}(1:minSize);
end
SpikeData.hist = hists;
stimDuration = Condition.stimDuration;
stimDiffTime = Condition.stimDiffTime;
timeFrom = Condition.timeFrom;
centers = cell2mat(Condition.centers);
binSize = Condition.binSize;

%% Rasters
% Sort the histograms by stim time
[~, ix] = sort(SpikeData.stimTime);
SpikeData = SpikeData(ix,:);

% Make a title
titleStr = makeTitle(Params, elecNo, cell);
conditions = Params.ConditionTable.condition;
conditionNo = Params.ConditionTable.conditionNo;

% Plot raster
hRaster = figure('Visible',showFigure);
set(hRaster,'Color','White');
suptitle(titleStr);
ax = subplot(1,1,1);
hold on;
colors = hsv(length(conditionNo));
for i = 1:size(SpikeData,1)
    
    c = SpikeData.conditionNo(i);

    % Plot vertical lines
    spikes = SpikeData.raster{i};
    nSpikes = size(spikes,1);
    xx=ones(3*nSpikes,1)*nan;
    yy=ones(3*nSpikes,1)*nan;
    if ~isempty(spikes)
        yy(1:3:3*nSpikes)=i;
        yy(2:3:3*nSpikes)=i+max(1, size(SpikeData,1)/100);
        
        %scale the time axis to ms
        xx(1:3:3*nSpikes)=spikes;
        xx(2:3:3*nSpikes)=spikes;
        plot(ax, xx, yy, 'Color', colors(c,:))
    end
    
end

fontSize = 5;
tickDistance = max(0.1, round(stimDiffTime/10, 1, ...
    'significant')); % maximum 20 ticks
box(ax,'off');
xlabel(ax, 'Time [s]');
ylabel(ax, 'Trial');
set(ax,'FontSize',fontSize);
axis(ax, [-timeFrom stimDiffTime-timeFrom 0 ...
    i+1]);
tick = 0:-tickDistance:-timeFrom; % always include 0
tick = [fliplr(tick) tickDistance:tickDistance:stimDiffTime-timeFrom];

% Mark stim duration
set(ax,'XTick',tick);
v = [0 0; stimDuration 0; ...
    stimDuration i+1; 0 i+1];
f = [1 2 3 4];
patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
    'FaceAlpha',0.1,'EdgeColor','none');

hold off;

%% Histogram
hPSTH = figure('Visible',showFigure);
set(hPSTH,'Color','White');
suptitle(titleStr);

% Make just one subplot
ax = subplot(1,1,1);
histograms = zeros(length(centers),1);
for i = 1:length(conditionNo)
    
    c = conditionNo(i);
   
    % Sum the hists
    histogram = cell2mat(SpikeData{SpikeData.conditionNo == c, 'hist'}');
    histograms = histograms + mean(histogram,2)./binSize; % spike density
    
end
% Plot histogram
b = bar(ax,centers,histograms,'hist');
set(b, 'FaceColor', color, 'EdgeColor',color);
maxY = max(1, max(histograms));

axis(ax,[-timeFrom stimDiffTime-timeFrom 0 maxY]);

% Font size, XTick, and title
box(ax,'off');
set(ax,'FontSize',fontSize);
tick = 0:-tickDistance:-timeFrom; % always include 0
tick = [fliplr(tick) tickDistance:tickDistance:stimDiffTime-timeFrom];
ylabel(ax, 'spikes/s');
xlabel(ax, 'Time [s]');

% Mark stim duration in red
set(ax,'XTick',tick);
v = [0 0; stimDuration 0; ...
    stimDuration maxY; 0 maxY];
f = [1 2 3 4];
patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
    'FaceAlpha',0.1,'EdgeColor','none');

handle = {hRaster, hPSTH};
suffix = {'raster_all', 'psth_all'};