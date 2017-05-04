function titleStr = makeTitle(Params, elecNo, unit, OSI, DI)

if nargin < 10
    OSI = [];
    DI = [];
end

titleStr = sprintf('%d [%s] Cell %d   Elec %d\n ', Params.ExpNo, Params.StimType, ...
    unit, elecNo);

% if isfield(Params,'SF')
%     Title = sprintf('%sSF=%.3f ', Title, mean(Params.SF));
% end
% if isfield(Params,'TF')
%     Title = sprintf('%sTF=%.1f ', Title, mean(Params.TF));
% end
% if isfield(Params,'Apt')
%     Title = sprintf('%sApt=%d ', Title, mean(Params.Apt));
% end
% if isfield(Params,'C')
%     Title = sprintf('%sCon=%d ', Title, mean(Params.C));
% end
% if isfield(Params,'Ori')
%     Title = sprintf('%sOri=%.2f ', Title, mean(Params.Ori));
% end
if ~isempty(OSI)
    titleStr = sprintf('%sOSI=%.2f ', titleStr, OSI);
end
if ~isempty(DI)
    titleStr = sprintf('%sDI=%.2f ', titleStr, DI);
end