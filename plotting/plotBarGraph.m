function [ handle ] = plotBarGraph(Statistics, ...
    Params, color, showFigure, elecNo, cell)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

conditions = Params.Conditions.condition;
conditionNo = Params.Conditions.conditionNo;

% Sort conditions properly
tCurve = Statistics.tCurve(Statistics.conditionNo);
tCurveSEM = Statistics.tCurveSEM(Statistics.conditionNo);
blank = Statistics.blank(Statistics.conditionNo);
blankSEM = Statistics.blankSEM(Statistics.conditionNo);

% Open a figure
handle = figure;
set(handle,'Visible',showFigure);
set(handle,'Color','White')
hold on;

% Configure data for grouped bar graph
data = [tCurve blank];
if length(conditions) > 1
    conditions_ = repmat(conditions, 1, 2);
    data_ = [tCurve blank];
else
    conditions_ = [1.5 3.5];
    data_ = [tCurve blank; 0 0];
end
errorNeg = [tCurveSEM blankSEM];
errorPos = [tCurveSEM blankSEM];
errorNeg(data > 0) = NaN;
errorPos(data < 0) = NaN;
colors = [color' [0.5 0.5 0.5]' [0.25 0.25 0.25]'];

% Plot baseline
if length(conditions) > 1
    baseline = mean(blank);
    line([conditions(1)-1 conditions(end)+1],[baseline baseline],'Color','blue');
end

% Plot data as bars
h = bar(conditions_, data_);
set(h,'BarWidth',1);

% Remove dummy data
if length(conditions) == 1
    ax = axis;
    ax(2) = 2.5;
    axis(ax);
end

% Add SEMs
numGroups = size(data, 1);
numBars = size(data, 2);
groupWidth = min(0.8, numBars/(numBars+1.5));
for i = 1:numBars
    
    % Set the color properly
    h(i).FaceColor = colors(:,i);
    h(i).EdgeColor = colors(:,i);
    
    % Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
    if length(conditions) > 1
        x = (1:numGroups) - groupWidth/2 + (2*i-1) * groupWidth / (2*numBars);
    else
        groupWidth_ = 0.65 + groupWidth;
        x = 0.5 + (1:numGroups) - groupWidth_/2 + (2*i-1) * groupWidth_ / (2*numBars); 
    end
    errorbar(x, data(:,i), errorNeg(:,i), errorPos(:,i), ...
        'Color', colors(:,i), 'linestyle', 'none');
end

% Fix y axis
ylim auto;

% Set the title, legends, etc.
xlabel(Params.stimType);
ylabel('Rate [spikes/s]');
set(gca,'FontSize',6);
if length(conditions) > 1
    set(gca,'XTick',conditions);
    legend('avg bg','Mean FR','bg','Location','NorthEast');
else
    set(gca,'XTick',[]);
    legend('Mean FR','bg','Location','NorthEast');
end
legend('boxoff');
box off;
titleStr = makeTitle(Params, elecNo, cell);
title(titleStr, 'FontSize', 16, 'FontWeight', 'normal');

% Add grid lines
set(gca,'YGrid','on')
set(gca,'GridLineStyle','-')

hold off;
end

