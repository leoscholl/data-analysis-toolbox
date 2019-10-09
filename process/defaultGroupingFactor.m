function groupingFactor = defaultGroupingFactor(conditionNames)
% Take 'Final' factors by default, otherwise take the first
gId = find(contains(conditionNames,'Final'),1);
if isempty(conditionNames)
    groupingFactor = [];
elseif ~isempty(gId)
    groupingFactor = conditionNames{gId};
elseif length(conditionNames) == 1
    groupingFactor = conditionNames{1};
elseif all(contains(conditionNames, 'Laser')) && ismember('LaserIndex', conditionNames)
    groupingFactor = 'LaserIndex';
elseif strcmp('LaserIndex', conditionNames{1})
    groupingFactor = conditionNames{2};
else
    groupingFactor = conditionNames{1};
end