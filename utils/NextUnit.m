
% --- increment a unit no
function Unit = NextUnit (Unit)
Unit = strcat('Unit',num2str(str2num(Unit(5:end))+1));