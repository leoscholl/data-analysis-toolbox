function [ handle ] = plotBarGraph(Statistics, ...
    Params, ShowFigure)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

conditions = Params.Conditions.Cond;
conditionNo = Params.Conditions.CondNo;

% Sort conditions properly
tCurve = Statistics.TCurve(Statistics.CondNo);
tCurveSEM = Statistics.TCurveSEM(Statistics.CondNo);
blank = Statistics.Blank(Statistics.CondNo);
blankSEM = Statistics.BlankSEM(Statistics.CondNo);

% Open a figure
handle = figure;
set(handle,'Visible',ShowFigure);
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
colors = [[0 0 0]' [0.5 0.5 0.5]' [0 1 0]'];

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
numgroups = size(data, 1);
numbars = size(data, 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
    
    % Set the color properly
    h(i).FaceColor = colors(:,i);
    h(i).EdgeColor = colors(:,i);
    
    % Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
    if length(conditions) > 1
        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);
    else
        groupwidth_ = 0.65 + groupwidth;
        x = 0.5 + (1:numgroups) - groupwidth_/2 + (2*i-1) * groupwidth_ / (2*numbars); 
    end
    errorbar(x, data(:,i), errorNeg(:,i), errorPos(:,i), ...
        'Color', colors(:,i), 'linestyle', 'none');
end

% Fix y axis
ylim auto;

% Set the title, legends, etc.
titleStr = makeTitle(Params, Params.ElecNo, Params.Unit);
title(titleStr, 'FontSize', 16);
xlabel(Params.StimType);
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

% Add grid lines
set(gca,'YGrid','on')
set(gca,'GridLineStyle','-')

hold off;
end

