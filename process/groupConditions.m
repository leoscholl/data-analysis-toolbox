function groups = ...
    groupConditions(ex, groupingFactor, groupingMethod, filter)
%groupConditions Define conditions based on different grouping schemes
%
% groupingMethod:
%   'all' - group everything into the groupingFactor
%   'remaining' - after grouping into the groupingFactor, group everything
%       else into separate levels of one factor
%   'first' - after grouping into the groupingFactor, don't do any more
%       grouping
%   'none' - don't use the groupingFactor, just use the unique conditions
%       to make one level
%   'merge' - merge everything into one condition


if ~exist('groupingFactor', 'var') || isempty(groupingFactor)
    conditionNames = fieldnames(ex.CondTestCond);
    groupingFactor = defaultGroupingFactor(conditionNames);
end

if ~exist('filter', 'var') || isempty(filter)
    filter = true(size(ex.CondTest.CondIndex));
else
    filter = reshape(filter, size(ex.CondTest.CondIndex));
end

% Identify unique conditions
allFactors = fieldnames(ex.CondTestCond);
allConds = [];
allDim = [];
for f = 1:length(allFactors)
    factor = allFactors{f};
    conditions = ex.CondTestCond.(factor);
    conditions = reshape(conditions, length(conditions), 1);
    conditions = conditions(filter);
    allConds = [allConds conditions];
    allDim = [allDim size(conditions{1},2)];
end
[uniqueValues, ~, idx] = unique(cell2mat(allConds),'rows');

% Organize conditions into groups
factorNames = setdiff(fieldnames(ex.CondTestCond), groupingFactor);
if ~isempty(groupingFactor)
    groupingConditions = ex.CondTestCond.(groupingFactor);
    groupingConditions = reshape(groupingConditions, length(groupingConditions), 1);
    groupingConditions = groupingConditions(filter);
    groupingValues = unique(cell2mat(groupingConditions),'rows');
end

remainingFactors = {};
remainingFactorNames = {};
rDim = [];
for f = 1:length(factorNames)
    factor = factorNames{f};
    conditions = ex.CondTestCond.(factor);
    conditions = reshape(conditions, length(conditions), 1);
    conditions = conditions(filter);

    % If any two factors share the same condition indices, only include the
    % first one (e.g. PositionOffset and Position_Final)
    u = [];
    allConds = [groupingConditions remainingFactors conditions];
    allNames = [{''} remainingFactorNames factorNames{f}];
    rDim = [-1 rDim size(conditions{1},2)];
    for i = 1:size(allConds,2)
        [~, ~, u(:,i)] = unique(cell2mat(allConds(:,i)),'rows');
    end
    [~, c] = unique(u', 'rows');
    c = setdiff(c,1);
    remainingFactors = allConds(:,c);
    remainingFactorNames = allNames(c);
    rDim = rDim(c);
    rCond = unique(cell2mat(remainingFactors),'rows');
    rCond = mat2cell(rCond, ones(1,size(rCond,1)), rDim);
end

if ~exist('groupingMethod', 'var') || isempty(groupingMethod)
    if length(uniqueValues) > 12
        groupingMethod = 'remaining';
    else
        groupingMethod = 'none';
    end
end

if isempty(ex.CondTestCond) || strcmp(groupingMethod, 'merge')
    
    % No factors or merge factors = 1 condition
    groupingFactor = 'merge';
    groupingValues = [1];
    conditions = filter;
    if strcmp(groupingMethod, 'merge')
        labels = {'merge'};
    else
        labels = {''};
    end

elseif strcmp(groupingMethod, 'all') || isempty(remainingFactors)

    % No additional factors
    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex));
    labels = {''};
    
    for i = 1:size(groupingValues, 1)
        conditions(i,:) = cellfun(@(x)isequal(x,groupingValues(i,:)), ...
            ex.CondTestCond.(groupingFactor));
    end
    
elseif strcmp(groupingMethod, 'remaining') 
    
    % Collapse remaining conditions into one
    condString = cellfun(@(x)sprintf('%g_',x),rCond,'UniformOutput', false);
    condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);

    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex), size(rCond,1));
    labels = cell(1, size(rCond,1));
    for l = 1:size(rCond,1)


        group = zeros(size(ex.CondTest.CondIndex));
        for i = 1:length(ex.CondTest.CondIndex)
            match = 1;
            for f = 1:length(remainingFactorNames)
                match = match && all(rCond{l,f} == ...
                    ex.CondTestCond.(remainingFactorNames{f}){i});
            end
            group(i) = match;
        end
        for i = 1:size(groupingValues, 1)
            condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                ex.CondTestCond.(groupingFactor));
            conditions(i,:,l) = condition & group;
        end
        levelName = [remainingFactorNames; condString(l,:)];
        levelName = sprintf('%s_%s_', levelName{:});
        labels{l} = levelName(1:end-1);
    end

elseif strcmp(groupingMethod, 'first')
    
    % Don't collapse anything
    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex), 0);
    labels = cell(1, 0);
    ll = 1;
    for f = 1:size(remainingFactors,2)
        rCond = unique(cell2mat(remainingFactors(:,f)),'rows');
        rCond = mat2cell(rCond, ones(1,size(rCond,1)), rDim(f));
        
        condString = cellfun(@(x)sprintf('%g_',x),rCond,'UniformOutput', false);
        condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);
        
        for l = 1:size(rCond,1)
            group = zeros(size(ex.CondTest.CondIndex));
            for i = 1:length(ex.CondTest.CondIndex)
                group(i) = all(rCond{l} == ...
                    ex.CondTestCond.(remainingFactorNames{f}){i});
            end
            for i = 1:size(groupingValues, 1)
                condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                    ex.CondTestCond.(groupingFactor));
                conditions(i,:,ll) = condition & group;
            end
            levelName = [remainingFactorNames{f}; condString(l)];
            levelName = sprintf('%s_%s_', levelName{:});
            labels{ll} = levelName(1:end-1);
            ll = ll + 1;
        end
    end
    
elseif strcmp(groupingMethod, 'none')
    
    % No grouping, just use unique condition indices
    groupingFactor = allFactors;
    groupingValues = uniqueValues;
    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex));
    for i = 1:size(groupingValues, 1)
        conditions(i,:) = arrayfun(@(x)x==i, idx);
    end
    groupingValues = mat2cell(groupingValues, ones(1,size(groupingValues,1)), allDim);
    labels = {''};
else
    error(['Unknown collapsing method. Choose ''all'' (default), ',...
        '''remaining'', or ''none''.']);
end

% Organize into structure
groups.factor = groupingFactor;
groups.values = groupingValues;
groups.conditions = conditions;
groups.levelNames = labels;

% Generate labels for grouped conditions
groups.labels = cell(1,size(groups.values,1));
if iscell(groups.factor)
    for i = 1:size(groups.values,1)
        label = cell(1,length(groups.factor));
        for j = 1:length(groups.factor)
            label{j} = strcat(groups.factor{j}, ' =', ...
                sprintf(' %g', groups.values{i,j}));
        end
        groups.labels{i} = strjoin(label, ', ');
    end
else  
    for i = 1:size(groups.values,1)
        groups.labels{i} = strcat(groups.factor, ' =', ...
            sprintf(' %g', groups.values(i,:)));
    end
end