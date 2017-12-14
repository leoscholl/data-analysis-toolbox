function titleStr = makeTitle(Params, elecNo, unit)

if nargin < 3 || isempty(unit)
    titleStr = sprintf('%d [%s] Elec %d', Params.expNo, Params.stimType, elecNo);
else
    titleStr = sprintf('%d [%s] Cell %d   Elec %d', Params.expNo, Params.stimType, ...
        unit, elecNo);
end