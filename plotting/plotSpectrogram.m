function [ handle, suffix ] = plotSpectrogram(Statistics, SpikeData, ...
    Params, color, showFigure, elecNo, cell)
%plotSpectrogram opens and draws spike spectrogram

titleStr = makeTitle(Params, elecNo, cell);
conditions = Params.ConditionTable.condition;
conditionNo = Params.ConditionTable.conditionNo;

% Plot spectrogram
handle = figure('Visible',showFigure);
set(handle,'Color','White');
suptitle(titleStr);
hold on;
for i = 1:length(conditionNo)
    
    c = conditionNo(i);
    Stimuli = Params.Data(Params.Data.conditionNo == c,:);
    Condition = Params.ConditionTable(Params.ConditionTable.conditionNo == c,:);
    
    stimDuration = Condition.stimDuration;
    stimDiffTime = Condition.stimDiffTime;
    timeFrom = Condition.timeFrom;
    
    % Make a two-column subplot
    if length(conditionNo) > 1
        ax = subplot(ceil(length(conditionNo)/2),2,i);
        fontSize = 4;
    else
        ax = subplot(1,1,1);
        fontSize = 5;
    end
    
    % Plot vertical lines
    rasters = SpikeData.raster(SpikeData.conditionNo == c);

    spec = {};
    for j = 1:length(rasters)
        if length(rasters{j}) > 8
            spec = [spec {spectrogram(rasters{j})}];
        end
    end
    
    % For subplots, only label the bottommost axes
    showXTick = length(unique(Params.ConditionTable.stimDuration)) > 1;
    if i == length(conditionNo) || i == length(conditionNo) - 1 || showXTick
        if i == length(conditionNo) || mod(length(conditionNo),2) == 0
            xlabel(ax, 'Time [s]');
        end
    else
        set(ax, 'XTickLabel', []);
%         set(ax2, 'XTickLabel', []);
    end
    if length(conditionNo) > 1 && isnumeric(conditions)
        title(ax, sprintf('%s = %.3f', Params.stimType, conditions(c)), ...
            'FontSize',fontSize,'FontWeight','Normal', 'Interpreter', 'none');
    elseif length(conditionNo) > 1 && iscellstr(conditions)
        title(ax, sprintf('%s', conditions{c}), ...
            'FontSize',fontSize,'FontWeight','Normal', 'Interpreter', 'none');
    end
    ylabel(ax, 'Trial');
    
end
hold off;
