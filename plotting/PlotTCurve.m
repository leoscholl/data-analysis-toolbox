function [ handle, OSI, DI ] = PlotTCurve(TCurve, TCurveSEM, Blank, BlankSEM, ...
    F1Rep, F1RepSD, TCurveCorr, TCurveCorrSEM, Params, ShowFigure)
%PlotTCurve opens and draws a tuning curve figure
% returns the handle to the tuning curve figure

OSI = []; DI = [];
Conditions = Params.Conditions.Cond;
ConditionNo = Params.Conditions.CondNo;

FontSize = 5;

% Sort conditions properly
TCurve = TCurve(ConditionNo);
TCurveSEM = TCurveSEM(ConditionNo);
Blank = Blank(ConditionNo);
BlankSEM = BlankSEM(ConditionNo);
TCurveCorr = TCurveCorr(ConditionNo);
TCurveCorrSEM = TCurveCorrSEM(ConditionNo);
if ~isempty(F1Rep) && ~isempty(F1RepSD)
    F1Rep = F1Rep(ConditionNo);
    F1RepSD = F1RepSD(ConditionNo);
end

% Adding 360 deg to Ori tunning
if strcmp(Params.StimType,'Ori')
    F1Rep(end+1) = F1Rep(1); F1RepSD(end+1) = F1RepSD(1);
    Blank(end+1) = Blank(1); BlankSEM(end+1) = BlankSEM(1);
    TCurveCorr(end+1) = TCurveCorr(1);
    TCurveCorrSEM(end+1) = TCurveCorrSEM(1);
    TCurve(end+1) = TCurve(1);
    TCurveSEM(end+1) = TCurveSEM(1);
    Conditions(end+1) = 360;
end

handle = figure;
set(handle,'Visible',ShowFigure);
set(handle,'Color','White')
hold on;

% Plot baseline
Baseline = mean(Blank);
line([Conditions(1) Conditions(end)],[Baseline Baseline],'Color','blue');

% Plot data with SEMs
errorbar(Conditions,TCurve,TCurveSEM,'k','LineWidth',1);
if ~(isempty(F1Rep) || isempty(F1RepSD))
    % || any(ismissing(F1Rep)) || any(ismissing(F1RepSD)))
    errorbar(Conditions,F1Rep,F1RepSD,'r');
end
errorbar(Conditions,Blank,BlankSEM,'Color',[0.5 0.5 0.5]);
errorbar(Conditions,TCurveCorr, TCurveCorrSEM,'g');


% Configure axes, legend, title
axis tight;
if isempty(F1Rep) || isempty(F1RepSD)
%        || any(ismissing(F1Rep)) || any(ismissing(F1RepSD))
    legend({'avg bg';'Mean FR';'bg';'FR-bg'},'Location','NorthEast');
else
    legend({'avg bg';'Mean FR';'F1';'bg';'FR-bg'},'Location','NorthEast');
end
legend('boxoff');
Title = MakeTitle(Params, Params.ElecNo, Params.Unit);
    
xlabel(Params.StimType);
ylabel('Rate [spikes/s]');
set(gca,'FontSize',FontSize);
set(gca,'XTick',Conditions);
box off;

% Orientation Selectivity Index
if strcmp(Params.StimType,'Ori')==1
    R = TCurve - Baseline; % subtract baseline
    [RPref, RPrefInd] = max(TCurve); % take the maximum value
    Opref = Conditions(RPrefInd);
    
    % calculate OSI for two halfs and choose higher. number
    % 2 - changes to 360 degree because we have 16
    % directions but only 8 orientations
    Aperture1 = Conditions(1:8);
    R1 = R(1:8); R2 = R(9:16);
    
    OSI1 = abs(sum(R1.*exp(1i.*2.*deg2rad(Aperture1(:)))))/sum(abs(R1));
    OSI1 = round(OSI1*100)/100;
    OSI2 = abs(sum(R2.*exp(1i.*2.*deg2rad(Aperture1(:)))))/sum(abs(R2));
    OSI2 = round(OSI2*100)/100;
    
    OSI = max([OSI1,OSI2]);
    DI = abs(sum(R.*exp(1i.*deg2rad(Conditions(:)))))/sum(abs(R));
    
    Title = MakeTitle(Params, Params.ElecNo, Params.Unit, OSI, DI);
end

% Change the title
title(Title, 'FontSize', 16);
hold off;
end

