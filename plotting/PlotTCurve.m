function [ handle, OSI, DI ] = plotTCurve(Statistics, Params, ShowFigure)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

OSI = []; DI = [];
conditions = Params.Conditions.Cond;
conditionNo = Params.Conditions.CondNo;

FontSize = 5;

% Sort conditions properly
tCurve = Statistics.TCurve(Statistics.CondNo);
tCurveSEM = Statistics.TCurveSEM(Statistics.CondNo);
blank = Statistics.Blank(Statistics.CondNo);
blankSEM = Statistics.BlankSEM(Statistics.CondNo);
tCurveCorr = Statistics.TCurveCorr(Statistics.CondNo);
tCurveCorrSEM = Statistics.TCurveCorrSEM(Statistics.CondNo);
if ~isempty(Statistics.F1Rep) && ~isempty(Statistics.F1RepSD)
    f1Rep = Statistics.F1Rep(Statistics.CondNo);
    f1RepSD = Statistics.F1RepSD(Statistics.CondNo);
end

% Adding 360 deg to Ori tunning
if strcmp(Params.StimType,'Ori')
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
titleStr = makeTitle(Params, Params.ElecNo, Params.Unit);
    
xlabel(Params.StimType);
ylabel('Rate [spikes/s]');
set(gca,'FontSize',FontSize);
set(gca,'XTick',conditions);
box off;

% Orientation Selectivity Index
if strcmp(Params.StimType,'Ori')==1
    R = tCurve - baseline; % subtract baseline
    [RPref, RPrefInd] = max(tCurve); % take the maximum value
    Opref = conditions(RPrefInd);
    
    % calculate OSI for two halfs and choose higher. number
    % 2 - changes to 360 degree because we have 16
    % directions but only 8 orientations
    aperture1 = conditions(1:8);
    R1 = R(1:8); R2 = R(9:16);
    
    OSI1 = abs(sum(R1.*exp(1i.*2.*deg2rad(aperture1(:)))))/sum(abs(R1));
    OSI1 = round(OSI1*100)/100;
    OSI2 = abs(sum(R2.*exp(1i.*2.*deg2rad(aperture1(:)))))/sum(abs(R2));
    OSI2 = round(OSI2*100)/100;
    
    OSI = max([OSI1,OSI2]);
    DI = abs(sum(R.*exp(1i.*deg2rad(conditions(:)))))/sum(abs(R));
    
    titleStr = makeTitle(Params, Params.ElecNo, Params.Unit, OSI, DI);
end

% Change the title
title(titleStr, 'FontSize', 16);
hold off;
end

