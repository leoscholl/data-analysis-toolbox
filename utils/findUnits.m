function [units, Units] = findUnits(baseDir, animalID, whichUnits)
%findUnits returns a cell array of units

narginchk(2,3);

if nargin < 3
    whichUnits = [];
end

if ~isnumeric(whichUnits)
    error('whichUnits only accepts numeric input');
end

units = dir(fullfile(baseDir,animalID,'Unit*'));
units = units(find(vertcat(units.isdir)));
units = {units.name};
unitNos = cellfun(@(x) str2double(x(5:end)), units);

% WhichUnits = [1:length(Units(:,1))];
% WhichUnits = [1,2,5,6,7,8,9,10];
if ~isempty(whichUnits)
    whichUnits = ismember(unitNos, whichUnits);
    units = units(whichUnits);
    unitNos = unitNos(whichUnits);
end

% Sort units
[~, idx] = sort(unitNos);
units = {units{idx}};

Units = cell2table(units');
Units.number = unitNos(idx)';
Units.Properties.VariableNames = {'name', 'number'};

end