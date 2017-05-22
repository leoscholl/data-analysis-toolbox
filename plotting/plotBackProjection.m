function [ handle ] = plotBackProjection(map, Params, showFigure)
%PlotMaps Function plotting RF maps

% Get conditions from parameters
screenSize = Params.screenRect/Params.ppd;
n = length(map);
X = 1:screenSize(3)/n:screenSize(3);
Y = 1:screenSize(4)/n:screenSize(4);

% Open a figure
handle = figure;
set(handle,'Visible',showFigure);
set(handle,'Color','White')
hold on;

% Plot data depending on matlab version
if verLessThan('matlab', '8.3') % < 2014
    contourf(1:n,1:n,map,20);
    shading(gca,'flat');
else % >= 2014
    surf(1:n,1:n,map,'FaceColor','interp');
    view(0,90);
    colormap('jet');
end

% Set the title, legends, etc.
xlabel('X [deg]');ylabel('Y [deg]');
axis([X(1) X(end) Y(1) Y(end)]);
xticks(X);
yticks(Y);

colorbar;
titleStr = makeTitle(Params, Params.elecNo, Params.unit);
title(titleStr, 'FontSize', 16);

box off;
hold off;
end