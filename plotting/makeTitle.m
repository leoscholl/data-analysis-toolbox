function titleStr = makeTitle(Params, elecNo, unit, OSI, DI)

if nargin < 4
    OSI = [];
    DI = [];
end

if nargin < 3 || isempty(unit)
    line1 = sprintf('%d [%s] Elec %d', Params.expNo, Params.stimType, elecNo);
else
    line1 = sprintf('%d [%s] Cell %d   Elec %d', Params.expNo, Params.stimType, ...
        unit, elecNo);
end
line2 = '';

if isfield(Params,'sf') && ~contains(Params.stimType, 'Spatial')
    line2 = sprintf('%sSF=%.3f ', line2, mean(Params.sf));
end
if isfield(Params,'tf') && ~contains(Params.stimType, 'Temporal')
    line2 = sprintf('%sTF=%.1f ', line2, mean(Params.tf));
end
if isfield(Params,'apt') && ~contains(Params.stimType, 'Aperture')
    line2 = sprintf('%sApt=%d ', line2, mean(Params.apterture));
end
if isfield(Params,'contrast') && ~contains(Params.stimType, 'Contrast')
    line2 = sprintf('%sCon=%d ', line2, mean(Params.contrast));
end
if isfield(Params,'ori') && ~contains(Params.stimType, 'Ori')
    line2 = sprintf('%sOri=%.2f ', line2, mean(Params.ori));
end
if ~isempty(OSI)
    line2 = sprintf('%sOSI=%.2f ', line2, OSI);
end
if ~isempty(DI)
    line2 = sprintf('%sDI=%.2f ', line2, DI);
end

if isempty(line2)
    titleStr = line1;
else
    titleStr = {line1,line2};
end