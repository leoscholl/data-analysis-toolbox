function titleStr = makeTitle(Params, elecNo, unit, OSI, DI)

if nargin < 10
    OSI = [];
    DI = [];
end

line1 = sprintf('%d [%s] Cell %d   Elec %d', Params.expNo, Params.stimType, ...
    unit, elecNo);
line2 = '';

if isfield(Params,'sf') && ~strfind(Params.stimType, 'Spatial')
    line2 = sprintf('%sSF=%.3f ', line2, mean(Params.sf));
end
if isfield(Params,'tf') && ~strfind(Params.stimType, 'Temporal')
    line2 = sprintf('%sTF=%.1f ', line2, mean(Params.tf));
end
if isfield(Params,'apt') && ~strfind(Params.stimType, 'Aperture')
    line2 = sprintf('%sApt=%d ', line2, mean(Params.apterture));
end
if isfield(Params,'contrast') && ~strfind(Params.stimType, 'Contrast')
    line2 = sprintf('%sCon=%d ', line2, mean(Params.contrast));
end
if isfield(Params,'ori') && ~strfind(Params.stimType, 'Ori')
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