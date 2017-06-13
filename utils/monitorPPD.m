function PPD = monitorPPD (Resolution, Diameter, Distance)
Diameter = Diameter*2.54;
PPI = sqrt((Resolution.width^2+Resolution.height^2))/Diameter; %#ok<NOPRT>
d = Distance;%/2.54; %I assume some distance here like 60cm
PPD = 2*d*PPI*tand(0.5); %This means how many pixels is in 1 degree for stimulus size
PPD = floor(PPD*10)/10; %#ok<NOPRT,NASGU>

% MonitorWidth = 122; % this is for tv in cm - change if you use different monitor
% MonitorHeigh = 69;
% params.sz = [MonitorWidth, MonitorHeigh];
% params.res=[Resolution.width Resolution.height];
% params.vdist=Distance;
% [PPD, ~] = VisAng(params); 
% PPD = PPD(2);
