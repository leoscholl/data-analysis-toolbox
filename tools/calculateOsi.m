function [ osi, di ] = calculateOsi(Statistics, Params)
%calculateOsi

osi = []; di = [];

% Sort conditions properly
conditions = Params.Conditions.condition;
tCurve = Statistics.tCurve(Statistics.conditionNo);
blank = Statistics.blank(Statistics.conditionNo);
baseline = mean(blank);

% Orientation Selectivity Index
if strcmp(Params.stimType,'Ori')==1
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
    
    osi = max([OSI1,OSI2]);
    di = abs(sum(R.*exp(1i.*deg2rad(conditions(:)))))/sum(abs(R));
end

end

