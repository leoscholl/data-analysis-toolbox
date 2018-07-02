function result = processData(dataset, figuresPath, actions, isParallel, varargin)

if length(dataset.ex.CondTest.CondIndex) < 3
    warning('Not enough condition tests, cannot process');
    result = [];
    return;
end

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('groupingFactor', defaultGroupingFactor(fieldnames(dataset.ex.CondTestCond)));
p.addParameter('groupingMethod', 'remaining');
p.addParameter('groupingFilter', []);
p.parse(varargin{:});

% Grouping
groups.factor = p.Results.groupingFactor;
groups.method = p.Results.groupingMethod;
groups.filter = p.Results.groupingFilter;
if isempty(groups.filter)
    filter = [];
else
    filter = groups.filter(dataset.ex);
end
[groups.values, groups.conditions, groups.levelNames] = ...
    groupConditions(dataset.ex, groups.factor, groups.method, ...
    filter);

% Labels for grouped conditions
groups.labels = cell(1,size(groups.values,1));
for i = 1:size(groups.values,1)
    groups.labels{i} = strcat(groups.factor, ' = ', ...
        sprintf(' %g', groups.values(i,:)));
end

% Make directories in sorted order
path = makeElectrodeDirs(dataset, figuresPath);

% Process and plot
ex = dataset.ex; ex.secondperunit = dataset.secondperunit;
[~, filename, ~] = fileparts(dataset.filepath);
spike = [];
lfp = [];
if isfield(dataset, 'spike')
    spike = dataset.spike;
end
if isfield(dataset, 'lfp')
    lfp = dataset.lfp.data;
    fs = dataset.lfp.fs;
    time = dataset.lfp.time;
    electrodeid = dataset.lfp.electrodeid;
end
spikeResult = cell(1,length(spike));
lfpResult = cell(1,length(electrodeid));
if ~isempty(spike)
    if isParallel
        parfor i = 1:length(spike)
            spikeResult{i} = processSpikeData(spike(i), ex, groups, ...
                path(spike(i).electrodeid), filename, actions, p.Unmatched);
        end
    else
        for i = 1:length(spike)
            spikeResult{i} = processSpikeData(spike(i), ex, groups, ...
                path(spike(i).electrodeid), filename, actions, p.Unmatched);
        end
    end
end
if ~isempty(lfp)
    if isParallel
        parfor i = 1:length(electrodeid)
            lfpResult{i} = processLfpData(lfp(:,i), fs, time, electrodeid(i),...
                ex, groups, path(electrodeid(i)), filename, actions, p.Unmatched);
        end
    else
        for i = 1:length(electrodeid)
            lfpResult{i} = processLfpData(lfp(:,i), fs, time, electrodeid(i),...
                ex, groups, path(electrodeid(i)), filename, actions, p.Unmatched);
        end
    end
end

% Summarize
path = makeDatasetDir(dataset, figuresPath);
result = processSummaryData(spikeResult, lfpResult, ex, groups, ...
    path, filename, actions, p.Unmatched);

end