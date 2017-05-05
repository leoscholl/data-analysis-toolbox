function [ hRaster, hPSTH ] = plotRastergrams( SpikeData,...
    Params, unitColors, showFigure )
%PlotRasters opens and draws raster plot and PSTH figures
%   hRaster - handle for rater plot
%   hPSTH - handle for PSTH

titleStr = makeTitle(Params, Params.elecNo, Params.unit);
conditions = Params.Conditions.condition;
conditionNo = Params.Conditions.conditionNo;

% Plot raster
hRaster = figure;
set(hRaster,'Visible',showFigure)
set(hRaster,'Color','White');
suptitle(titleStr);
hold on;
for i = 1:length(conditionNo)
    
    c = conditionNo(i);
    Stimuli = Params.Data(Params.Data.conditionNo == c,:);
    Condition = Params.Conditions(Params.Conditions.conditionNo == c,:);
    
    stimDuration = Condition.stimDuration;
    stimDiffTime = Condition.stimDiffTime;
    timeFrom = Condition.timeFrom;
    
    % Make a two-column subplot
    if length(conditionNo) > 1
        ax = subplot(ceil(length(conditionNo)/2),2,i);
        fontSize = 4;
        tickDistance = max(0.1, round(stimDiffTime/10, 1, ...
            'significant')); % maximum 10 ticks
    else
        ax = subplot(1,1,1);
        fontSize = 5;
        tickDistance = max(0.1, round(stimDiffTime/10, 1, ...
            'significant')); % maximum 20 ticks
    end
    
    % Plot vertical lines
    spikes = SpikeData{SpikeData.c == c, 'raster'};
    trials = SpikeData{SpikeData.c == c, 't'};
    allTrials = [];
    allSpikes = [];
    for t=1:size(spikes,1)
        s = spikes{t,:};
        allSpikes = [allSpikes;s];
        allTrials = [allTrials; repmat(trials(t), length(s), 1)];
    end
    nSpikes = size(allSpikes,1);
    xx=ones(3*nSpikes,1)*nan;
    yy=ones(3*nSpikes,1)*nan;
    if ~isempty(allSpikes)
        yy(1:3:3*nSpikes)=allTrials;
        yy(2:3:3*nSpikes)=allTrials+1;
        
        %scale the time axis to ms
        xx(1:3:3*nSpikes)=allSpikes;
        xx(2:3:3*nSpikes)=allSpikes;
        plot(ax, xx, yy, 'Color', unitColors(Params.unitNo,:))
    end;

    % Font size, XTick, and title
    box(ax,'off');
    set(ax,'FontSize',fontSize);
    axis(ax, [-timeFrom stimDiffTime-timeFrom 0 ...
        max(trials)+1]);
    tick = 0:-tickDistance:-timeFrom; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:stimDiffTime-timeFrom];
    
    % Mark stim duration
    set(ax,'XTick',tick);
    v = [0 0; stimDuration 0; ...
        stimDuration max(trials)+1; 0 max(trials)+1];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    showXTick = length(unique(Params.Conditions.stimDuration)) > 1;
    if i == length(conditionNo) || i == length(conditionNo) - 1 || showXTick
        if i == length(conditionNo) || mod(length(conditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
%         set(ax2, 'XTickLabel', []);
    end
    title(ax, sprintf('%s = %.3f', Params.stimType, conditions(c)), ...
        'FontSize',fontSize,'FontWeight','Normal');
    ylabel(ax, 'Trial');
    
end
hold off;

% Making latency analysis.
% [Latency,HistSmoothed] = CalculateLatency(Histogram,Time,un);
% LatencyAll{el,un} = Latency;
% HistSmoothedAll{el,un} = HistSmoothed;
% save([DataPath,FileName,'_latency.mat'],'LatencyAll','HistSmoothedAll','Time');

% plotting PSTHs
hPSTH = figure;
set(hPSTH,'Visible',showFigure);
set(hPSTH,'Color','White');
suptitle(titleStr);
hold on;
for i = 1:length(conditions)
    
    % Figure out the binsize
    c = conditionNo(i);
    Condition = Params.Conditions(Params.Conditions.conditionNo == c,:);
    
    stimDuration = Condition.stimDuration;
    stimDiffTime = Condition.stimDiffTime;
    timeFrom = Condition.timeFrom;
    centers = cell2mat(Condition.centers);
    binSize = Condition.binSize;
    
    % Get the hist
    histogram = cell2mat(SpikeData{SpikeData.c == c, 'hist'}');
    histogram = mean(histogram,2)./binSize; % spike density

    % Make a two-column subplot
    if length(conditionNo) > 1
        ax = subplot(ceil(length(conditionNo)/2),2,i);
        fontSize = 4;
        tickDistance = max(0.1, round(stimDiffTime/10, 1, ...
            'significant')); % maximum 10 ticks
    else
        ax = subplot(1,1,1);
        fontSize = 5;
        tickDistance = max(0.1, round(stimDiffTime/10, 1, ...
            'significant')); % maximum 20 ticks
    end
    
    % Plot histogram
    b = bar(ax,centers,histogram,'hist');
    set(b, 'FaceColor',unitColors(Params.unitNo,:),...
        'EdgeColor',unitColors(Params.unitNo,:));
    maxY = max([1; histogram]);
    axis(ax,[-timeFrom stimDiffTime-timeFrom 0 maxY]);
    
    % Font size, XTick, and title
    box(ax,'off');
    set(ax,'FontSize',fontSize);
    tick = 0:-tickDistance:-timeFrom; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:stimDiffTime-timeFrom];
    
    % Mark stim duration in red
    set(ax,'XTick',tick);
    v = [0 0; stimDuration 0; ...
        stimDuration max([1; histogram]); 0 max([1; histogram])];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    showXTick = length(unique(Params.Conditions.stimDuration)) > 1;
    if i == length(conditionNo) || i == length(conditionNo) - 1 || showXTick
        if i == length(conditionNo) || mod(length(conditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
%         set(ax2, 'XTickLabel', []);
    end
    title(ax, sprintf('%s = %.3f', Params.stimType, conditions(c)), ...
        'FontSize',fontSize,'FontWeight','Normal');
    ylabel(ax, 'spikes/s');
    
end
hold off;

