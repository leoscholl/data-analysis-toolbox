function result = processData(dataset, figuresPath, actions, isParallel, varargin)

if length(dataset.ex.CondTest.CondIndex) < 3
    warning('Not enough condition tests, cannot process');
    result = [];
    return;
end

p = inputParser;
p.KeepUnmatched = true;
p.addParameter('groupingFactor', '');
p.addParameter('groupingMethod', '');
p.addParameter('groupingFilter', []);
p.parse(varargin{:});

% Grouping
if isempty(p.Results.groupingFilter)
    filter = [];
elseif isnumeric(p.Results.groupingFilter)
    filter = p.Results.groupingFilter;
else
    filter = p.Results.groupingFilter(dataset.ex);
end
groups = groupConditions(dataset.ex, p.Results.groupingFactor, ...
    p.Results.groupingMethod, filter);

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
path = makeDatasetDir(dataset, figuresPath);
result = processSummaryData(spikeResult, lfpResult, ex, groups, ...
    path, filename, actions, p.Unmatched);

end