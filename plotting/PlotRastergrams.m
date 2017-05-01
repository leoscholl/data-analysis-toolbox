function [ hRaster, hPSTH ] = PlotRastergrams( SpikeData,...
    Params, UnitColors, ShowFigure )
%PlotRasters opens and draws raster plot and PSTH figures
%   hRaster - handle for rater plot
%   hPSTH - handle for PSTH

Title = MakeTitle(Params, Params.ElecNo, Params.Unit);
Conditions = Params.Conditions.Cond;
ConditionNo = Params.Conditions.CondNo;

% Plot raster
hRaster = figure;
set(hRaster,'Visible',ShowFigure)
set(hRaster,'Color','White');
suptitle(Title);
hold on;
for i = 1:length(ConditionNo)
    
    c = ConditionNo(i);
    Stimuli = Params.Data(Params.Data.ConditionNo == c,:);
    Condition = Params.Conditions(Params.Conditions.CondNo == c,:);
    
    StimDuration = Condition.StimDuration;
    StimDiffTime = Condition.StimDiffTime;
    TimeFrom = Condition.TimeFrom;
    
    % Make a two-column subplot
    if length(ConditionNo) > 1
        ax = subplot(ceil(length(ConditionNo)/2),2,i);
        FontSize = 4;
        TickDistance = max(0.1, round(StimDiffTime/10, 1, ...
            'significant')); % maximum 10 ticks
    else
        ax = subplot(1,1,1);
        FontSize = 5;
        TickDistance = max(0.1, round(StimDiffTime/10, 1, ...
            'significant')); % maximum 20 ticks
    end
    
    % Plot vertical lines
    Spikes = SpikeData{SpikeData.c == c, 'Raster'};
    Trials = SpikeData{SpikeData.c == c, 't'};
    AllTrials = [];
    AllSpikes = [];
    for t=1:size(Spikes,1)
        s = Spikes{t,:};
        AllSpikes = [AllSpikes;s];
        AllTrials = [AllTrials; repmat(Trials(t), length(s), 1)];
    end
    nSpikes = size(AllSpikes,1);
    xx=ones(3*nSpikes,1)*nan;
    yy=ones(3*nSpikes,1)*nan;
    if ~isempty(AllSpikes)
        yy(1:3:3*nSpikes)=AllTrials;
        yy(2:3:3*nSpikes)=AllTrials+1;
        
        %scale the time axis to ms
        xx(1:3:3*nSpikes)=AllSpikes;
        xx(2:3:3*nSpikes)=AllSpikes;
        plot(ax, xx, yy, 'Color', UnitColors(Params.UnitNo,:))
    end;

    % Font size, XTick, and title
    box(ax,'off');
    set(ax,'FontSize',FontSize);
    axis(ax, [-TimeFrom StimDiffTime-TimeFrom 0 ...
        max(Trials)+1]);
    Tick = 0:-TickDistance:-TimeFrom; % always include 0
    Tick = [fliplr(Tick) TickDistance:TickDistance:StimDiffTime-TimeFrom];
    
    % Mark stim duration
    set(ax,'XTick',Tick);
    v = [0 0; StimDuration 0; ...
        StimDuration max(Trials)+1; 0 max(Trials)+1];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    ShowXTick = length(unique(Params.Conditions.StimDuration)) > 1;
    if i == length(ConditionNo) || i == length(ConditionNo) - 1 || ShowXTick
        if i == length(ConditionNo) || mod(length(ConditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
%         set(ax2, 'XTickLabel', []);
    end
    title(ax, sprintf('%s = %.3f', Params.StimType, Conditions(c)), ...
        'FontSize',FontSize,'FontWeight','Normal');
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
set(hPSTH,'Visible',ShowFigure);
set(hPSTH,'Color','White');
suptitle(Title);
hold on;
for i = 1:length(Conditions)
    
    % Figure out the binsize
    c = ConditionNo(i);
    Stimuli = Params.Data(Params.Data.ConditionNo == c,:);
    Condition = Params.Conditions(Params.Conditions.CondNo == c,:);
    
    StimDuration = Condition.StimDuration;
    StimDiffTime = Condition.StimDiffTime;
    TimeFrom = Condition.TimeFrom;
    Centers = cell2mat(Condition.Centers);
    binsize = Condition.binsize;
    
    % Get the hist
    Histogram = cell2mat(SpikeData{SpikeData.c == c, 'Hist'}');
    Histogram = mean(Histogram,2)./binsize; % spike density
    
    % Make a two-column subplot
    if length(ConditionNo) > 1
        ax = subplot(ceil(length(ConditionNo)/2),2,i);
        FontSize = 4;
        TickDistance = max(0.1, round(StimDiffTime/10, 1, ...
            'significant')); % maximum 10 ticks
    else
        ax = subplot(1,1,1);
        FontSize = 5;
        TickDistance = max(0.1, round(StimDiffTime/10, 1, ...
            'significant')); % maximum 20 ticks
    end
    
    % Plot histogram
    b = bar(ax,Centers,Histogram,'hist');
    set(b, 'FaceColor',UnitColors(Params.UnitNo,:),...
        'EdgeColor',UnitColors(Params.UnitNo,:));
    axis(ax,[-TimeFrom StimDiffTime-TimeFrom 0 max([1; Histogram])]);
    
    % Font size, XTick, and title
    box(ax,'off');
    set(ax,'FontSize',FontSize);
    Tick = 0:-TickDistance:-TimeFrom; % always include 0
    Tick = [fliplr(Tick) TickDistance:TickDistance:StimDiffTime-TimeFrom];
    
    % Mark stim duration in red
    set(ax,'XTick',Tick);
    v = [0 0; StimDuration 0; ...
        StimDuration max([1; Histogram]); 0 max([1; Histogram])];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    ShowXTick = length(unique(Params.Conditions.StimDuration)) > 1;
    if i == length(ConditionNo) || i == length(ConditionNo) - 1 || ShowXTick
        if i == length(ConditionNo) || mod(length(ConditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
%         set(ax2, 'XTickLabel', []);
    end
    title(ax, sprintf('%s = %.3f', Params.StimType, Conditions(c)), ...
        'FontSize',FontSize,'FontWeight','Normal');
    ylabel(ax, 'spikes/s');
    
end
hold off;

