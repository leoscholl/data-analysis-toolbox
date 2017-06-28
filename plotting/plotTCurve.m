function [ handle, OSI, DI ] = plotTCurve(Statistics, Params, ShowFigure, ...
    elecNo, cell)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

OSI = []; DI = [];
conditions = Params.Conditions.condition;
conditionNo = Params.Conditions.conditionNo;

fontSize = 5;

% Sort conditions properly
tCurve = Statistics.tCurve(Statistics.conditionNo);
tCurveSEM = Statistics.tCurveSEM(Statistics.conditionNo);
blank = Statistics.blank(Statistics.conditionNo);
blankSEM = Statistics.blankSEM(Statistics.conditionNo);
tCurveCorr = Statistics.tCurveCorr(Statistics.conditionNo);
tCurveCorrSEM = Statistics.tCurveCorrSEM(Statistics.conditionNo);
if ~isempty(Statistics.f1Rep) && ~isempty(Statistics.f1RepSD)
    f1Rep = Statistics.f1Rep(Statistics.conditionNo);
    f1RepSD = Statistics.f1RepSD(Statistics.conditionNo);
end

% Adding 360 deg to Ori tunning
if strcmp(Params.stimType,'Ori')
    f1Rep(end+1) = f1Rep(1); f1RepSD(end+1) = f1RepSD(1);
    blank(end+1) = blank(1); blankSEM(end+1) = blankSEM(1);
    tCurveCorr(end+1) = tCurveCorr(1);
    tCurveCorrSEM(end+1) = tCurveCorrSEM(1);
    tCurve(end+1) = tCurve(1);
    tCurveSEM(end+1) = tCurveSEM(1);
    conditions(end+1) = 360;
    conditionNo(end+1) = conditionNo(1);
end

handle = figure;
set(handle,'Visible',ShowFigure);
set(handle,'Color','White')
hold on;

% Plot baseline
baseline = mean(blank);
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
    
xlabel(Params.stimType);
ylabel('Rate [spikes/s]');
set(gca,'FontSize',fontSize);
set(gca,'XTick',conditions);
box off;

% Change the title
title(titleStr, 'FontSize', 16, 'FontWeight', 'normal');
hold off;
end

