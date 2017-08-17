function [ handle, OSI, DI ] = plotTCurve(Statistics, Params, ShowFigure, ...
    elecNo, cell)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

OSI = []; DI = [];

fontSize = 5;

% Sort conditions properly
conditions = Params.ConditionTable.condition;
[conditions, conditionNo] = sort(conditions);

tCurve = Statistics.tCurve(conditionNo);
tCurveSEM = Statistics.tCurveSEM(conditionNo);
blank = Statistics.blank(conditionNo);
blankSEM = Statistics.blankSEM(conditionNo);
tCurveCorr = Statistics.tCurveCorr(conditionNo);
tCurveCorrSEM = Statistics.tCurveCorrSEM(conditionNo);
if ~isempty(Statistics.f1Rep) && ~isempty(Statistics.f1RepSD)
    f1Rep = Statistics.f1Rep(conditionNo);
    f1RepSD = Statistics.f1RepSD(conditionNo);
end

handle = figure;
set(handle,'Visible',ShowFigure);
set(handle,'Color','White')
hold on;

% Plot baseline
if any(conditions == -1)
    baseline = tCurve(conditions == -1); % remove -1 as blank
    conditions = conditions(conditions ~= -1);
    conditionNo = conditionNo(conditions ~= -1);
    tCurve = tCurve(conditions ~= -1);
    tCurveSEM = tCurveSEM(conditions ~= -1);
    blank = blank(conditions ~= -1);
    blankSEM = blankSEM(conditions ~= -1);
    tCurveCorr = tCurveCorr(conditions ~= -1);
    tCurveCorrSEM = tCurveCorrSEM(conditions ~= -1);
    if ~isempty(Statistics.f1Rep) && ~isempty(Statistics.f1RepSD)
        f1Rep = f1Rep(conditions ~= -1);
        f1RepSD = f1RepSD(conditions ~= -1);
    end
else
    baseline = mean(blank);
end
line([conditions(1) conditions(end)],[baseline baseline],'Color','blue');

% Plot data with SEMs
errorbar(conditions,tCurve,tCurveSEM,'k','LineWidth',1);
if ~(isempty(f1Rep) || isempty(f1RepSD))
    % || any(ismissing(F1Rep)) || any(ismissing(F1RepSD)))
    errorbar(conditions,f1Rep,f1RepSD,'r');
end
errorbar(conditions,blank,blankSEM,'Color',[0.5 0.5 0.5]);
errorbar(conditions,tCurveCorr, tCurveCorrSEM,'g');


% Configure axes, legend, title
axis tight;
if isempty(f1Rep) || isempty(f1RepSD)
%        || any(ismissing(F1Rep)) || any(ismissing(F1RepSD))
    legend({'avg bg';'Mean FR';'bg';'FR-bg'},'Location','NorthEast');
else
    legend({'avg bg';'Mean FR';'F1';'bg';'FR-bg'},'Location','NorthEast');
end
legend('boxoff');
titleStr = makeTitle(Params, elecNo, cell);
    
xlabel(fieldnames(Params.Conditions), 'Interpreter', 'none');
ylabel('Rate [spikes/s]');
set(gca,'FontSize',fontSize);
if issorted(conditions)
    set(gca,'XTick',conditions);
else
    set(gca,'XTickLabel',num2str(conditions));
end
box off;

% Change the title
title(titleStr, 'FontSize', 16, 'FontWeight', 'normal', 'Interpreter', 'none');
hold off;
end

