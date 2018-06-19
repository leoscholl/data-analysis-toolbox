function [groupingValues, conditions, conditionNames] = ...
    groupConditions(ex, groupingFactor, groupingMethod, filter)
%factorLevels Define conditions based on different grouping schemes

if ~exist('groupingFactor', 'var') || isempty(groupingFactor)
    conditionNames = fieldnames(ex.CondTestCond);
    % Take Final if possible, otherwise take the first by default
    groupingFactor = conditionNames{contains(conditionNames, 'Final')};
    if isempty(groupingFactor)
        groupingFactor = conditionNames{1}; 
    end
end

if ~exist('filter', 'var') || isempty(filter)
    filter = true(1, length(ex.CondTest.CondIndex));
else
    filter = reshape(filter, 1, length(filter));
end

if ~exist('groupingMethod', 'var') || isempty(groupingMethod)
    groupingMethod = 'all';
end

% No factors = 1 condition
if isempty(ex.CondTestCond)
    groupingValues = [];
    conditions = filter;
    conditionNames = {''};
    return;
end

% Organize conditions into groups
factorNames = setdiff(fieldnames(ex.CondTestCond), groupingFactor);
groupingConditions = ex.CondTestCond.(groupingFactor);
groupingConditions = reshape(groupingConditions, length(groupingConditions), 1);
groupingValues = unique(cell2mat(groupingConditions),'rows');

remainingFactors = {};
remainingFactorNames = {};
dim = [];
for f = 1:length(factorNames)
    factor = factorNames{f};
    conditions = ex.CondTestCond.(factor);
    conditions = reshape(conditions, length(conditions), 1);
    
    % If any two factors share the same condition indices, only include the
    % first one (e.g. PositionOffset and Position_Final)
    u = [];
    all = [groupingConditions remainingFactors conditions];
    allNames = [{''} remainingFactorNames factorNames{f}];
    dim = [-1 dim size(conditions,2)];
    for i = 1:size(all,2)
        [~, ~, u(:,i)] = unique(cell2mat(all(:,i)),'rows');
    end
    [~, c] = unique(u', 'rows');
    c = setdiff(c,1);
    remainingFactors = all(:,c);
    remainingFactorNames = allNames(c);
    dim = dim(c);
    rCond = unique(cell2mat(remainingFactors),'rows');
    rCond = mat2cell(rCond, ones(1,size(rCond,1)), dim);
end

if strcmp(groupingMethod, 'all') || isempty(remainingFactors)
    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex));
    conditionNames = {''};
    
    for i = 1:size(groupingValues, 1)
        conditions(i,:) = filter & cellfun(@(x)isequal(x,groupingValues(i,:)), ...
            ex.CondTestCond.(groupingFactor));
    end
    return;
end

if strcmp(groupingMethod, 'remaining') % collapse remaining conditions into one
    
    condString = cellfun(@(x)sprintf('%0.3f_',x),rCond,'UniformOutput', false);
    condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);

    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex), size(rCond,1));
    conditionNames = cell(1, size(rCond,1));
    for l = 1:size(rCond,1)


        group = zeros(length(ex.CondTest.CondIndex),1);
        for i = 1:length(ex.CondTest.CondIndex)
            match = 1;
            for f = 1:length(remainingFactorNames)
                match = match && rCond{l,f} == ...
                    ex.CondTestCond.(remainingFactorNames{f}){i};
            end
            group(i) = match;
        end
        for i = 1:size(groupingValues, 1)
            condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                ex.CondTestCond.(groupingFactor));
            condition = reshape(condition, length(condition), 1);
            conditions(i,:,l) = filter & condition & group;
        end
        levelName = [remainingFactorNames; condString(l,:)];
        levelName = sprintf('%s_%s_', levelName{:});
        conditionNames{l} = levelName(1:end-1);
    end

elseif strcmp(groupingMethod, 'none')
    
    conditions = false(size(groupingValues,1), length(ex.CondTest.CondIndex), 0);
    conditionNames = cell(1, 0);
    ll = 1;
    for f = 1:size(remainingFactors,2)
        rCond = unique(cell2mat(remainingFactors(:,f)),'rows');
        rCond = mat2cell(rCond, ones(1,size(rCond,1)), dim(f));
        
        condString = cellfun(@(x)sprintf('%0.3f_',x),rCond,'UniformOutput', false);
        condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);
        
        for l = 1:size(rCond,1)
            group = zeros(1, length(ex.CondTest.CondIndex));
            for i = 1:length(ex.CondTest.CondIndex)
                group(i) = rCond{l} == ...
                    ex.CondTestCond.(remainingFactorNames{f}){i};
            end
            for i = 1:size(groupingValues, 1)
                condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                    ex.CondTestCond.(groupingFactor));
                conditions(i,:,ll) = filter & condition & group;
            end
            levelName = [remainingFactorNames{f}; condString(l)];
            levelName = sprintf('%s_%s_', levelName{:});
            conditionNames{ll} = levelName(1:end-1);
            ll = ll + 1;
        end
    end
    
else
    error(['Unknown collapsing method. Choose ''all'' (default), ',...
        '''remaining'', or ''none''.']);
end