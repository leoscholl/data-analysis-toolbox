function result = processData(dataset, figuresPath, plotFun, isParallel, varargin)

if length(dataset.ex.CondTest.CondIndex) < 3
    warning('Not enough condition tests, cannot process');
    result = [];
    return;
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
            spikeResult{i} = processSpikeData(spike(i), ...
                ex, path(spike(i).electrodeid), filename, plotFun, varargin{:});
        end
    else
        for i = 1:length(spike)
            spikeResult{i} = processSpikeData(spike(i), ...
                ex, path(spike(i).electrodeid), filename, plotFun, varargin{:});
        end
    end
end
if ~isempty(lfp)
    if isParallel
        parfor i = 1:length(electrodeid)
            lfpResult{i} = processLfpData(lfp(:,i), fs, time, electrodeid(i),...
                ex, path(electrodeid(i)), filename, plotFun, varargin{:});
        end
    else
        for i = 1:length(electrodeid)
            lfpResult{i} = processLfpData(lfp(:,i), fs, time, electrodeid(i),...
                ex, path(electrodeid(i)), filename, plotFun, varargin{:});
        end
    end
end

% Summarize
path = makeDatasetDir(dataset, figuresPath);
result = processSummaryData(spikeResult, lfpResult, ex, path, filename, plotFun, varargin{:});

end