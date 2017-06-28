function [Electrodes, Params, StimTimes, LFP, AnalogIn, hasError, errorMsg] ...
    = loadExperiment(dataDir, animalID, unit, fileName, sourceFormat)

if nargin < 5 || isempty(sourceFormat)
    sourceFormat = {'Plexon', 'Ripple'};
end

[~, fileName, ~] = fileparts(fileName);
[~, fileNo, stimType] = parseFileName(fileName);
fileName = createFileName(animalID, fileNo, stimType);
unitNo = str2num(unit(5:end));
dataPath = fullfile(dataDir, animalID, unit, filesep);
filePath = fullfile(dataPath,[fileName,'.mat']);

% Make sure some variables exist in case they are non-existent in the file
Electrodes = [];
Params = [];
StimTimes = [];
LFP = [];
AnalogIn = [];

% Load the file
if ~exist(filePath)
    warning(['No data for ', fileName]);
    hasError = 2;
    return;
end
file = load(filePath, 'dataset');

% Pick which data to load
whichData = [];
i = 1;
while isempty(whichData)
    if i > length(sourceFormat)
        warning('Unsupported filetype');
        hasError = 2;
        return;
    end
    whichData = find(strcmp({file.dataset.sourceformat}, sourceFormat{i}));
    i = i + 1;
end
dataset = file.dataset(:,whichData);

% Check data
if ~exist('dataset','var')
    warning(['No data for ', fileName]);
    hasError = 2;
    return;
end
if ~isfield(dataset,'spike')
    warning(['No spikes for ', fileName]);
    hasError = 2;
    return;
end



% Check params
if ~isfield(dataset,'ex') || ~isfield(dataset.ex, 'Params') ...
        || ~isfield(dataset.ex.Params,'Data')
    warning(['Missing Params for ', fileName]);
    hasError = 2;
    return;
end

% Check LFP
if ~isfield(dataset,'lfp')
    % Attempt to convert from ripple
    warning(['No LFP for ', fileName]);
    hasError = 2;
    return;
end

% Check Analog
if ~isfield(dataset,'analog1k')
    % Attempt to convert from ripple
    warning(['No analog data for ', fileName]);
    hasError = 2;
    return;
end


% Check Events
if ~isfield(dataset,'digital')
    warning(['No digital events for ', fileName]);
    hasError = 2;
    return;
end



% Convert everything into a nice format
[ Electrodes, LFP, AnalogIn, Events ] = convertDataset( dataset );
Params = dataset.ex.Params;

% Adjust StimTimes
StimTimes = Events.StimTimes;
StimTimes.matlab = Params.Data.stimTime;

Params.unitNo = unitNo;
[stimOnTimes, stimOffTimes, source, latency, variation, hasError, errorMsg] = ...
    adjustStimTimes(Params, Events);

StimTimes.on = stimOnTimes;
StimTimes.off = stimOffTimes;
StimTimes.latency = latency;
StimTimes.variation = variation;
StimTimes.source = source;

end