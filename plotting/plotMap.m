function [ handle, suffix ] = plotMap(Statistics, SpikeData, ...
    Params, color, showFigure, elecNo, cell)
%PlotMaps Function plotting RF maps

suffix = 'map';

% Get conditions from parameters
conditions = Params.ConditionTable.condition;
conditionNo = Params.ConditionTable.conditionNo;
X = unique(conditions(:,1));
Y = unique(conditions(:,2));

tCurve = Statistics.tCurve(Statistics.conditionNo);
tCurveSEM = Statistics.tCurveSEM(Statistics.conditionNo);
blank = Statistics.blank(Statistics.conditionNo);
blankSEM = Statistics.blankSEM(Statistics.conditionNo);
tCurveCorr = Statistics.tCurveCorr(Statistics.conditionNo);
tCurveCorrSEM = Statistics.tCurveCorrSEM(Statistics.conditionNo);
if ~isempty(Statistics.f1) && ~isempty(Statistics.f1SD)
    f1 = Statistics.f1(Statistics.conditionNo);
    f1SD = Statistics.f1SD(Statistics.conditionNo);
end

% Sort conditions properly
for i = 1:length(conditionNo)
    c = conditionNo(i);
    x = conditions(i,1);
    y = conditions(i,2);
    ix = find(X == x);
    iy = find(Y == y);
    onmap(iy,ix) = tCurve(c);
    blankmap(iy,ix) = blank(c);
    corrmap(iy,ix) = tCurveCorr(c);
    idx(iy,ix) = i; % for testing
end

% Smoothing
% smoothmap = smooth2a(onmap,2,2) - blankmap;

% Open a figure
handle = figure;
set(handle,'Visible',showFigure);
set(handle,'Color','White')
hold on;

% Plot data depending on matlab version
if verLessThan('matlab', '8.3') % < 2014
    contourf(X,Y,corrmap,20);
    shading(gca,'flat');
else % >= 2014
    surf(X,Y,corrmap,'FaceColor','interp');
    view(0,90);
    colormap('jet');
end

% Set the title, legends, etc.
xlabel('X [deg]');ylabel('Y [deg]');
axis tight;

colorbar;
titleStr = makeTitle(Params, elecNo, cell);
title(titleStr, 'FontSize', 16, 'FontWeight', 'normal');

box off;
hold off;
end