function [ handle ] = PlotMap(TCurve, Params, ShowFigure)
%PlotMaps Function plotting RF maps

% Get conditions from parameters
Conditions = Params.Conditions.Cond;
ConditionNo = Params.Conditions.CondNo;
X = unique(Conditions(:,1));
Y = unique(Conditions(:,2));

% Sort conditions properly
for i = 1:length(ConditionNo)
    c = ConditionNo(i);
    x = Conditions(c,1);
    y = Conditions(c,2);
    ix = find(X == x);
    iy = find(Y == y);
    Map(iy,ix) = TCurve(c);
    IX(iy,ix) = i; % for testing
end

% Open a figure
handle = figure;
set(handle,'Visible',ShowFigure);
set(handle,'Color','White')
hold on;

% Plot data depending on matlab version
if verLessThan('matlab', '8.3') % < 2014
    contourf(X,Y,Map,20);
    shading(gca,'flat');
else % >= 2014
    surf(X,Y,Map,'FaceColor','interp');
    view(0,90);
    colormap('jet');
end

% Set the title, legends, etc.
xlabel('X [deg]');ylabel('Y [deg]');
axis tight;
xticks(X);
yticks(Y);

colorbar;
Title = MakeTitle(Params, Params.ElecNo, Params.Unit);
title(Title, 'FontSize', 16);

box off;
hold off;
end