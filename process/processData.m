function result = processData(dataset, figuresPath, plotFun, isParallel)

if length(dataset.ex.CondTest.CondIndex) < 3
    warning('Dataset too small, cannot process');
    result = [];
    return;
end

% Make directories in sorted order
path = containers.Map('KeyType','double','ValueType','char');
if ~isempty(dataset.ex.RecordSession) && ~isempty(dataset.ex.RecordSite)
    session = sprintf('%s_%s',dataset.ex.RecordSession,dataset.ex.RecordSite);
else
    session = sprintf('%s%s',dataset.ex.RecordSession,dataset.ex.RecordSite);
end
electrodes = union([dataset.spike.electrodeid], dataset.lfp.electrodeid);
for i = 1:length(electrodes)
    fileDir = fullfile(figuresPath,dataset.ex.Subject_ID,session,...
        sprintf('Ch%02d',electrodes(i)));
    if ~isdir(fileDir)
        mkdir(fileDir)
    end
    path(electrodes(i)) = fileDir;
end

% Process and plot
spike = dataset.spike;
data = dataset.lfp.data;
fs = dataset.lfp.fs;
time = dataset.lfp.time;
electrodeid = dataset.lfp.electrodeid;
ex = dataset.ex; ex.secondperunit = dataset.secondperunit;
[~, filename, ~] = fileparts(dataset.filepath);
spikeResult = cell(1,length(spike));
lfpResult = cell(1,length(electrodeid));
if isParallel
    parfor i = 1:length(spike)
        spikeResult{i} = processSpikeData(spike(i), ...
            ex, path(spike(i).electrodeid), filename, plotFun);
    end
    parfor i = 1:length(electrodeid)
        lfpResult{i} = processLfpData(data(i,:), fs, time, electrodeid(i),...
            ex, path(electrodeid(i)), filename, plotFun);
    end
else
    for i = 1:length(spike)
        spikeResult{i} = processSpikeData(spike(i), ...
            ex, path(spike(i).electrodeid), filename, plotFun);
    end
    for i = 1:length(electrodeid)
        lfpResult{i} = processLfpData(data(:,i), fs, time, electrodeid(i),...
            ex, path(electrodeid(i)), filename, plotFun);
    end
end

% Summarize
path = fullfile(figuresPath,dataset.ex.Subject_ID,session);
result = processSummaryData(spikeResult, lfpResult, ex, path, filename, plotFun);

end