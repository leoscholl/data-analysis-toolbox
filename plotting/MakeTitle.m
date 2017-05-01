function Title = MakeTitle(Params, ElecNo, Unit, OSI, DI)

if nargin < 10
    OSI = [];
    DI = [];
end

Title = sprintf('%d [%s] Cell %d   Elec %d\n ', Params.ExpNo, Params.StimType, ...
    Unit, ElecNo);

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
    Title = sprintf('%sOSI=%.2f ', Title, OSI);
end
if ~isempty(DI)
    Title = sprintf('%sDI=%.2f ', Title, DI);
end