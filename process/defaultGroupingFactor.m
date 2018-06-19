function groupingFactor = defaultGroupingFactor(conditionNames)
% Take 'Final' factors by default, otherwise take the first
gId = find(contains(conditionNames,'Final'),1);
if isempty(gId)
    groupingFactor = conditionNames{1};
else
    groupingFactor = conditionNames{gId};
end
end