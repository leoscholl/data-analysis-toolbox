function [ handle ] = PlotBarGraph(TCurve, TCurveSEM, Blank, BlankSEM, ...
    Params, ShowFigure)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

Conditions = Params.Conditions.Cond;
ConditionNo = Params.Conditions.CondNo;

% Sort conditions properly
TCurve = TCurve(ConditionNo);
TCurveSEM = TCurveSEM(ConditionNo);
Blank = Blank(ConditionNo);
BlankSEM = BlankSEM(ConditionNo);

% Open a figure
handle = figure;
set(handle,'Visible',ShowFigure);
set(handle,'Color','White')
hold on;

% Configure data for grouped bar graph
Data = [TCurve Blank];
if length(Conditions) > 1
    Conditions_ = repmat(Conditions, 1, 2);
    Data_ = [TCurve Blank];
else
    Conditions_ = [1.5 3.5];
    Data_ = [TCurve Blank; 0 0];
end
ErrorNeg = [TCurveSEM BlankSEM];
ErrorPos = [TCurveSEM BlankSEM];
ErrorNeg(Data > 0) = NaN;
ErrorPos(Data < 0) = NaN;
Colors = [[0 0 0]' [0.5 0.5 0.5]' [0 1 0]'];

% Plot baseline
if length(Conditions) > 1
    Baseline = mean(Blank);
    line([Conditions(1)-1 Conditions(end)+1],[Baseline Baseline],'Color','blue');
end

% Plot data as bars
h = bar(Conditions_, Data_);
set(h,'BarWidth',1);

% Remove dummy data
if length(Conditions) == 1
    ax = axis;
    ax(2) = 2.5;
    axis(ax);
end

% Add SEMs
numgroups = size(Data, 1);
numbars = size(Data, 2);
groupwidth = min(0.8, numbars/(numbars+1.5));
for i = 1:numbars
    
    % Set the color properly
    h(i).FaceColor = Colors(:,i);
    h(i).EdgeColor = Colors(:,i);
    
    % Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
    if length(Conditions) > 1
        x = (1:numgroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*numbars);
    else
        groupwidth_ = 0.65 + groupwidth;
        x = 0.5 + (1:numgroups) - groupwidth_/2 + (2*i-1) * groupwidth_ / (2*numbars); 
    end
    errorbar(x, Data(:,i), ErrorNeg(:,i), ErrorPos(:,i), ...
        'Color', Colors(:,i), 'linestyle', 'none');
end

% Fix y axis
ylim auto;

% Set the title, legends, etc.
Title = MakeTitle(Params, Params.ElecNo, Params.Unit);
title(Title, 'FontSize', 16);
xlabel(Params.StimType);
ylabel('Rate [spikes/s]');
set(gca,'FontSize',6);
if length(Conditions) > 1
    set(gca,'XTick',Conditions);
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

