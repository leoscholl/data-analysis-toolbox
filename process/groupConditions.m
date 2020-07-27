function groups = ...
    groupConditions(ctCond, groupingFactor, groupingMethod, filter, ignoreFactors)
%groupConditions Define conditions based on different grouping schemes
%
% groupingFactor (optional):
%   <factor name> - group conditions by this factor
%
% groupingMethod (optional, default 'none'):
%   'all' - group everything into groupingFactor
%   'remaining' - after grouping into groupingFactor, group everything
%       else into unique conditions
%   'first' - after grouping into the groupingFactor, don't do any more
%       grouping
%   'none' - don't use the groupingFactor, just use the unique conditions
%       to make one level
%   'merge' - merge everything into one condition
%
% filter (optional):
%   logical vector of length(condition tests) - filter condition tests
%
% ignoreFactors (optional):
%   list of factor names to ignore
%

conditionNames = fieldnames(ctCond);
if isempty(conditionNames)
    error('No conditions given');
end
nct = length(ctCond.(conditionNames{1}));

if ~exist('groupingFactor', 'var') || isempty(groupingFactor)
    groupingFactor = defaultGroupingFactor(conditionNames);
end

if ~exist('filter', 'var') || isempty(filter)
    filter = true(1, nct);
else
    filter = reshape(filter, 1, nct);
end

if ~exist('ignoreFactors', 'var') || isempty(ignoreFactors)
    ignoreFactors = {};
elseif ~iscell(ignoreFactors)
    ignoreFactors = {ignoreFactors};
end

% Identify unique conditions
allFactors = setdiff(fieldnames(ctCond), ignoreFactors);
allConds = [];
allDim = [];
for f = 1:length(allFactors)
    factor = allFactors{f};
    conditions = ctCond.(factor);
    conditions = reshape(conditions, length(conditions), 1);
    allConds = [allConds conditions];
    allDim = [allDim size(conditions{1},2)];
end
[uniqueValues, ~, idx] = unique(cell2mat(allConds),'rows');

% Organize conditions into groups
groupingConditions = {};
if ~isempty(groupingFactor)
    groupingConditions = ctCond.(groupingFactor);
    groupingConditions = reshape(groupingConditions, length(groupingConditions), 1);
    groupingValues = unique(cell2mat(groupingConditions),'rows');
end

remainingFactors = {};
remainingFactorNames = {};
rDim = [];
factorNames = setdiff(allFactors, groupingFactor);
for f = 1:length(factorNames)
    factor = factorNames{f};
    conditions = ctCond.(factor);
    conditions = reshape(conditions, length(conditions), 1);
    
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
    if length(uniqueValues) > 4
        groupingMethod = 'remaining';
    else
        groupingMethod = 'none';
    end
end

if isempty(ctCond) || strcmp(groupingMethod, 'merge')
    
    % No factors or merge factors = 1 condition
    groupingFactor = 'merge';
    groupingValues = [1];
    conditions = filter;
    labels = {''};

elseif strcmp(groupingMethod, 'all') || isempty(remainingFactors)

    % No additional factors
    conditions = false(size(groupingValues,1), nct);
    for i = 1:size(groupingValues, 1)
        conditions(i,:) = filter & cellfun(@(x)isequal(x,groupingValues(i,:)), ...
            reshape(ctCond.(groupingFactor), 1, length(ctCond.(groupingFactor))));
    end
    labels = {''};
    
elseif strcmp(groupingMethod, 'remaining') 
    
    % Collapse remaining conditions into one
    condString = cellfun(@(x)sprintf('%g_',x),rCond,'UniformOutput', false);
    condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);

    conditions = false(size(groupingValues,1), nct, size(rCond,1));
    labels = cell(1, size(rCond,1));
    for l = 1:size(rCond,1)


        group = zeros(1, nct);
        for i = 1:nct
            match = 1;
            for f = 1:length(remainingFactorNames)
                match = match && all(rCond{l,f} == ...
                    ctCond.(remainingFactorNames{f}){i});
            end
            group(i) = match;
        end
        for i = 1:size(groupingValues, 1)
            condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                ctCond.(groupingFactor));
            conditions(i,:,l) = filter & reshape(condition, 1, length(condition)) & group;
        end
        levelName = [remainingFactorNames; condString(l,:)];
        levelName = sprintf('%s_%s_', levelName{:});
        labels{l} = levelName(1:end-1);
    end

elseif strcmp(groupingMethod, 'first')
    
    % Don't collapse anything
    conditions = false(size(groupingValues,1), nct, 0);
    labels = cell(1, 0);
    ll = 1;
    for f = 1:size(remainingFactors,2)
        rCond = unique(cell2mat(remainingFactors(:,f)),'rows');
        rCond = mat2cell(rCond, ones(1,size(rCond,1)), rDim(f));
        
        condString = cellfun(@(x)sprintf('%g_',x),rCond,'UniformOutput', false);
        condString = cellfun(@(x)x(1:end-1),condString,'UniformOutput', false);
        
        for l = 1:size(rCond,1)
            group = zeros(1, nct);
            for i = 1:nct
                group(i) = all(rCond{l} == ...
                    ctCond.(remainingFactorNames{f}){i});
            end
            for i = 1:size(groupingValues, 1)
                condition = cellfun(@(x,y)isequal(x,groupingValues(i,:)),...
                    ctCond.(groupingFactor));
                conditions(i,:,ll) = filter & reshape(condition, 1, length(condition)) & group;
            end
            levelName = [remainingFactorNames{f}; condString(l)];
            levelName = sprintf('%s_%s_', levelName{:});
            labels{ll} = levelName(1:end-1);
            ll = ll + 1;
        end
    end
    
elseif strcmp(groupingMethod, 'none')
    
    % No grouping, just use unique condition indices
    idxfilt = unique(idx(filter));
    conditions = false(length(idxfilt), nct);
    for i = 1:length(idxfilt)
        group = reshape(arrayfun(@(x)x==idxfilt(i), idx), 1, nct);
        conditions(i,:) = filter & group;
    end
    groupingFactor = allFactors;
    groupingValues = uniqueValues(idxfilt,:);
    groupingValues = mat2cell(groupingValues, ones(1,size(groupingValues,1)), allDim);
    labels = {''};
else
    error(['Unknown collapsing method. Choose ''all'' (default), ',...
        '''remaining'', or ''none''.']);
end

% Remove any empty levels after filtering
empty = squeeze(all(all(~conditions,2)));
conditions(:,:,empty) = [];
labels(empty) = [];

% Organize into structure
groups.filter = filter;
groups.method = groupingMethod;
groups.factor = groupingFactor;
groups.values = groupingValues;
groups.ctc = groupingConditions;
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