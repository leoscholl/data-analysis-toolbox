function [Electrodes, Params, StimTimes, LFP, AnalogIn] ...
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

% Reload the data?
overwrite = 0; % if needed for testing

% Export the file to make sure everything is in place
dataExport( dataDir, [], animalID, unitNo, fileNo, overwrite);

% Load the file
if ~exist(filePath)
    error(['No data for ', fileName]);
end
load(filePath);

% Check spikes
switch fileType
    case 'unsorted'
        % Check Ripple spikes
        if ~exist('Ripple','var') || ~isfield(Ripple,'Electrodes')
            error(['No spikes for ', fileName]);
        end
        Electrodes = Ripple.Electrodes;
        
    case 'osort'
        if ~exist('OSort','var') || ~isfield(OSort,'Electrodes')
            error(['No sorted spikes (osort) for ', fileName]);
        end
        Electrodes = OSort.Electrodes;
        
    case 'plexon'
        if ~exist('Plexon','var') || ~isfield(Plexon,'Electrodes')
            error(['No sorted spikes (plexon) for ', fileName]);
        end
        Electrodes = Plexon.Electrodes;
    otherwise
        error('Unsupported filetype');
end

% Check params
if ~exist('Params', 'var')  || ~isfield(Params,'Data')
    error(['Missing Params for ', fileName]);
end

% Check LFP
if ~exist('Ripple', 'var') || ~isfield(Ripple,'LFP')
    % Attempt to convert from ripple
    error(['No LFP for ', fileName]);
else
    LFP = Ripple.LFP;
end

% Check Analog
if ~exist('Ripple', 'var') || ~isfield(Ripple,'AnalogIn')
    % Attempt to convert from ripple
    error(['No AnalogIn for ', fileName]);
else
    AnalogIn = Ripple.AnalogIn;
end

% Check Events
if ~exist('Ripple', 'var') || ~isfield(Ripple,'Events')
    error(['No digital events for ', fileName]);
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

if hasError
    plotStimTimes(dataPath, fileName);
end

end