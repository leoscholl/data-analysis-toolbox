function [ handle, suffix ] = plotTCurve(Statistics, SpikeData, ...
    Params, color, showFigure, elecNo, cell)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

fontSize = 5;
suffix = 'tc';

% Sort conditions properly
conditions = Params.ConditionTable.condition;
[conditions, conditionNo] = sort(conditions);

tCurve = Statistics.tCurve(conditionNo);
tCurveSEM = Statistics.tCurveSEM(conditionNo);
blank = Statistics.blank(conditionNo);
blankSEM = Statistics.blankSEM(conditionNo);
tCurveCorr = Statistics.tCurveCorr(conditionNo);
tCurveCorrSEM = Statistics.tCurveCorrSEM(conditionNo);
if ~isempty(Statistics.f1) && ~isempty(Statistics.f1SD)
    f1 = Statistics.f1(conditionNo);
    f1SD = Statistics.f1SD(conditionNo);
end

handle = figure;
set(handle,'Visible',showFigure);
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
    if ~isempty(Statistics.f1) && ~isempty(Statistics.f1SD)
        f1 = f1(conditions ~= -1);
        f1SD = f1SD(conditions ~= -1);
    end
else
    baseline = mean(blank);
end
line([conditions(1) conditions(end)],[baseline baseline],'Color','blue');

% Plot data with SEMs
errorbar(conditions,tCurve,tCurveSEM,'k','LineWidth',1);
if ~(isempty(f1) || isempty(f1SD))
    % || any(ismissing(f1)) || any(ismissing(f1SD)))
    errorbar(conditions,f1,f1SD,'r');
end
errorbar(conditions,blank,blankSEM,'Color',[0.5 0.5 0.5]);
errorbar(conditions,tCurveCorr, tCurveCorrSEM,'g');


% Configure axes, legend, title
axis tight;
if isempty(f1) || isempty(f1SD)
%        || any(ismissing(f1)) || any(ismissing(f1SD))
    legend({'avg bg';'Mean FR';'bg';'FR-bg'},'Location','NorthEast');
else
    legend({'avg bg';'Mean FR';'F1';'bg';'FR-bg'},'Location','NorthEast');
end
legend('boxoff');

xlabel(fieldnames(Params.Conditions), 'Interpreter', 'none');
ylabel('Rate [spikes/s]');
set(gca,'FontSize',fontSize);
if issorted(conditions, 'strictmonotonic') 
    set(gca,'XTick',conditions);
else
    set(gca,'XTick',unique(conditions));
end
box off;

% Set the x-scale
if ~isempty(strfind(Params.stimType,'Looming')) || ...
        contains(lower(Params.stimType),'velocity')
    set(gca,'xscale','log');
end

% Add annotation for parameters
OSI = [];
DSI = [];
if contains(Params.stimType, 'Ori')
    valid = conditions >= 0;
    theta = deg2rad(conditions(valid));
    response = tCurve(valid) - baseline;
    response(response < 0) = 0;
    
    [~, prefInd] = max(response);
    prefTheta = theta(prefInd);
    theta_ = mod(theta - prefTheta + pi/2, 2*pi);
    left = 0 <= theta_ &...
        theta_ < pi;
    
    OSI = abs(sum(response(left).*exp(2.1i*theta(left)))/sum(response(left)));

    DSI = abs(sum(response.*exp(1i*theta))/sum(response));
end
annoStr = makeParamBox(Params, OSI, DSI);
dim = [0.15 0.15 0.3 0.2];
annotation('textbox',dim,'String',annoStr,'FitBoxToText','on', ...
    'Interpreter', 'none', 'FontName', 'FixedWidth', 'FontSize', 5);

% Change the title
titleStr = makeTitle(Params, elecNo, cell);
title(titleStr, 'FontSize', 16, 'FontWeight', 'normal', 'Interpreter', 'none');
hold off;
end

