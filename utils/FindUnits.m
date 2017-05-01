function Units = FindUnits(Dir, AnimalID, WhichUnits)

narginchk(2,3);

if nargin < 3
    WhichUnits = [];
end

if ~isnumeric(WhichUnits)
    error('WhichUnits only accepts numeric input');
end

Units = dir(fullfile(Dir,AnimalID,'Unit*'));
Units = Units(find(vertcat(Units.isdir)));
Units = char(Units.name);

% WhichUnits = [1:length(Units(:,1))];
% WhichUnits = [1,2,5,6,7,8,9,10];
if ~isempty(WhichUnits)
    UnitsStr = cellstr(Units);
    WhichUnitsStr = strcat(cellstr(repmat('Unit',length(WhichUnits),1)),cellfun(@strtrim,cellstr(num2str(WhichUnits')),'UniformOutput',0));
    UnitsStr = UnitsStr(ismember(UnitsStr,WhichUnitsStr));
    Units = char(UnitsStr);
end

% Sort units
UnitsNo = str2num(deblank(Units(:,5:end)));
[~, UnID] = sort(UnitsNo);
Units = Units(UnID,:);

end