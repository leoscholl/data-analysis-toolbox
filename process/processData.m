function result = processData(dataset, figuresPath, actions, isParallel, varargin)

if contains(actions, 'skip')
    result = [];
    fprintf('Skipping %s\n', dataset.filepath);
    return;
end

% Trim condition table
nct = sum(dataset.ex.CondTest.CondIndex > 0);
nct = min(nct, sum(~isnan(dataset.ex.CondTest.CondOn)));
nct = min(nct, sum(~isnan(dataset.ex.CondTest.CondOff)));
ctf = fieldnames(dataset.ex.CondTest);
ctcf = fieldnames(dataset.ex.CondTestCond);
for f = 1:length(ctf)
    dataset.ex.CondTest.(ctf{f}) = dataset.ex.CondTest.(ctf{f})(1:nct);
end
for f = 1:length(ctcf)
    dataset.ex.CondTestCond.(ctcf{f}) = dataset.ex.CondTestCond.(ctcf{f})(1:nct);
end

if length(dataset.ex.CondTest.CondIndex) < 3
    warning('Not enough condition tests, cannot process %s', dataset.filepath);
    result = [];
    return;
end

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('groupingFactor', '');
p.addParameter('groupingMethod', '');
p.addParameter('groupingFilter', []);
p.addParameter('ignoreFactors', {});
p.parse(varargin{:});

% Grouping
if isempty(p.Results.groupingFilter)
    filter = [];
elseif isnumeric(p.Results.groupingFilter)
    filter = p.Results.groupingFilter;
else
    filter = p.Results.groupingFilter(dataset.ex.CondTestCond);
end
groups = groupConditions(dataset.ex.CondTestCond, p.Results.groupingFactor, ...
    p.Results.groupingMethod, filter, p.Results.ignoreFactors);

% Event timing mode
ex = dataset.ex; ex.secondperunit = dataset.secondperunit;
% pport = dataset.digital([dataset.digital.channel] == 1).time;
% ex.CondTest.CondOn = pport(1:2:end);
% ex.CondTest.CondOff = pport(2:2:end);

% Make directories in sorted order
path = makeElectrodeDirs(dataset, figuresPath);

% Process and plot
[~, filename, ~] = fileparts(dataset.filepath);
filename = strcat(filename, '_group_', groups.method);
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
path = makeDatasetDir(ex.Subject_ID, ex.RecordSite, ex.RecordSession, figuresPath);
result = processSummaryData(spikeResult, lfpResult, ex, groups, ...
    path, filename, actions, p.Unmatched);

end