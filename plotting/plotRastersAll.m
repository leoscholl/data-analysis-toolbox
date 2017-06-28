function hRaster = plotRastersAll( SpikeData,...
    Params, showFigure, elecNo, cell )
%PlotRasters opens and draws raster plot and PSTH figures
%   hRaster - handle for rater plot
%   hPSTH - handle for PSTH

% Truncate any long histograms to the same length
unpadded = SpikeData.hist;
minSize = min(cellfun('length',unpadded));
hists = [];
for k = 1:size(unpadded,1)
    hists{k,1} = unpadded{k}(1:minSize);
end
SpikeData.hist = hists;

% Sort the histograms by stim time
[~, ix] = sort(SpikeData.stimTime);
SpikeData = SpikeData(ix,:);

% Make a title
titleStr = makeTitle(Params, elecNo, cell);
conditions = Params.Conditions.condition;
conditionNo = Params.Conditions.conditionNo;

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
        yy(2:3:3*nSpikes)=i+1;
        
        %scale the time axis to ms
        xx(1:3:3*nSpikes)=spikes;
        xx(2:3:3*nSpikes)=spikes;
        plot(ax, xx, yy, 'Color', colors(c,:))
    end
    
end

Condition = Params.Conditions(Params.Conditions.conditionNo == 1,:);

stimDuration = Condition.stimDuration;
stimDiffTime = Condition.stimDiffTime;
timeFrom = Condition.timeFrom;

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