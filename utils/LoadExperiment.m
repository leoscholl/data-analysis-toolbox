function [hasError, Electrodes, Params, StimTimes, LFP, AnalogIn] ...
    = loadExperiment(dataDir, animalID, unit, fileName, fileType)

if nargin < 5 || isempty(fileType)
    fileType = 'unsorted';
end

[~, fileName, ~] = fileparts(fileName);
[~, fileNo, stimType] = parseFileName(fileName);
fileName = createFileName(animalID, fileNo, stimType);
unitNo = str2num(unit(5:end));
dataPath = fullfile(dataDir, animalID, unit, filesep);
filePath = fullfile(dataPath,[fileName,'-export.mat']);

% Reload from raw data?
overwrite = 0; % if needed for testing
if overwrite
    dataExport( dataDir, dataDir, animalID, unitNo, fileNo, 1);
end

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
load(filePath);

% Check spikes
switch fileType
    case 'unsorted'
        % Check Ripple spikes
        if ~exist('Ripple','var') || ~isfield(Ripple,'Electrodes')
            warning(['No spikes for ', fileName]);
            hasError = 2;
            return;
        end
        Electrodes = Ripple.Electrodes;
        
    case 'osort'
        if ~exist('OSort','var') || ~isfield(OSort,'Electrodes')
            warning(['No sorted spikes (osort) for ', fileName]);
            hasError = 2;
            return;
        end
        Electrodes = OSort.Electrodes;
        
    case 'plexon'
        if ~exist('Plexon','var') || ~isfield(Plexon,'Electrodes')
            warning(['No sorted spikes (plexon) for ', fileName]);
            hasError = 2;
            return;
        end
        Electrodes = Plexon.Electrodes;
    otherwise
        error('Unsupported filetype');
end

% Check params
if ~exist('Params', 'var')  || ~isfield(Params,'Data')
    warning(['Missing Params for ', fileName]);
    hasError = 2;
    return;
end

% Check LFP
if ~exist('Ripple', 'var') || ~isfield(Ripple,'LFP')
    % Attempt to convert from ripple
    warning(['No LFP for ', fileName]);
    hasError = 2;
    return;
else
    LFP = Ripple.LFP;
end

% Check Analog
if ~exist('Ripple', 'var') || ~isfield(Ripple,'AnalogIn')
    % Attempt to convert from ripple
    warning(['No AnalogIn for ', fileName]);
    hasError = 2;
    return;
else
    AnalogIn = Ripple.AnalogIn;
end

% Check Events
if ~exist('Ripple', 'var') || ~isfield(Ripple,'Events')
    warning(['No digital events for ', fileName]);
    hasError = 2;
    return;
else
    Events = Ripple.Events;
end

% Adjust StimTimes
Params.unitNo = unitNo;
[stimOnTimes, stimOffTimes, source, latency, variation, hasError] = ...
    adjustStimTimes(Params, Events);
StimTimes = [];
StimTimes.on = stimOnTimes;
StimTimes.off = stimOffTimes;
StimTimes.latency = latency;
StimTimes.variation = variation;
StimTimes.source = source;

end