function [ handle ] = plotMap(tCurve, Params, showFigure)
%PlotMaps Function plotting RF maps

% Get conditions from parameters
conditions = Params.Conditions.Cond;
conditionNo = Params.Conditions.CondNo;
X = unique(conditions(:,1));
Y = unique(conditions(:,2));

% Sort conditions properly
for i = 1:length(conditionNo)
    c = conditionNo(i);
    x = conditions(c,1);
    y = conditions(c,2);
    ix = find(X == x);
    iy = find(Y == y);
    map(iy,ix) = tCurve(c);
    idx(iy,ix) = i; % for testing
end

% Open a figure
handle = figure;
set(handle,'Visible',showFigure);
set(handle,'Color','White')
hold on;

% Plot data depending on matlab version
if verLessThan('matlab', '8.3') % < 2014
    contourf(X,Y,map,20);
    shading(gca,'flat');
else % >= 2014
    surf(X,Y,map,'FaceColor','interp');
    view(0,90);
    colormap('jet');
end

% Set the title, legends, etc.
xlabel('X [deg]');ylabel('Y [deg]');
axis tight;
xticks(X);
yticks(Y);

colorbar;
titleStr = makeTitle(Params, Params.ElecNo, Params.Unit);
title(titleStr, 'FontSize', 16);

box off;
hold off;
end