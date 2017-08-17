function [ handle ] = plotLFP(lfp, Params, showFigure)
%plotLFP Draw a per-condition plot of LFP data

elecNo = lfp.electrodeid;
titleStr = makeTitle(Params, elecNo);
conditions = Params.ConditionTable.condition;
conditionNo = Params.ConditionTable.conditionNo;

% Plot LFP
handle = figure('Visible',showFigure);
set(handle,'Color','White');
suptitle(titleStr);

hold on;
for i = 1:length(conditionNo)
    
    c = conditionNo(i);
    Condition = Params.ConditionTable(Params.ConditionTable.conditionNo == c,:);
    
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
    
    % Draw the LFP lines
    whichLFP = lfp.Data.conditionNo == c;
    time = lfp.Data.time{whichLFP};
    lfpMean = lfp.Data.mean{whichLFP};
    plot(time, lfpMean, 'b');
    
    minY = min([-1 lfpMean]);
    maxY = max([1 lfpMean]);
    axis(ax,[-timeFrom stimDiffTime-timeFrom minY maxY]);
    
    % Font size, XTick, and title
    box(ax,'off');
    set(ax,'FontSize',fontSize);
    tick = 0:-tickDistance:-timeFrom; % always include 0
    tick = [fliplr(tick) tickDistance:tickDistance:stimDiffTime-timeFrom];
    
    % Mark stim duration in red
    set(ax,'XTick',tick);
    v = [0 minY; stimDuration minY; ...
        stimDuration maxY; 0 maxY];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor',[0.5 0.5 0.5],...
        'FaceAlpha',0.1,'EdgeColor','none');

    % For subplots, only label the bottommost axes
    showXTick = length(unique(Params.ConditionTable.stimDuration)) > 1;
    if i == length(conditionNo) || i == length(conditionNo) - 1 || showXTick
        if i == length(conditionNo) || mod(length(conditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
    end
    title(ax, sprintf('%s = %.3f', Params.stimType, conditions(c)), ...
        'FontSize',fontSize,'FontWeight','Normal');
    ylabel(ax, 'Voltage [mV]');
    
end
hold off;
    
end