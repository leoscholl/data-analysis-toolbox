function [Electrodes, Params, StimTimes, LFP, AnalogIn, hasError, errorMsg] ...
    = loadExperiment(dataDir, animalID, unit, fileName, fileType)

if nargin < 5 || isempty(fileType)
    fileType = 'unsorted';
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
load(filePath);

% Check data
switch fileType
    case 'unsorted'
        % Check Ripple spikes
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
        if ~isfield(dataset,'Params')  || ~isfield(Params,'Data')
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
     
    otherwise
        warning('Unsupported filetype');
        hasError = 2;
        return;
end



% Adjust StimTimes
StimTimes = Events.StimTimes;
StimTimes.matlab = Params.StimTimes;

Params.unitNo = unitNo;
[stimOnTimes, stimOffTimes, source, latency, variation, hasError, errorMsg] = ...
    adjustStimTimes(Params, Events);

StimTimes.on = stimOnTimes;
StimTimes.off = stimOffTimes;
StimTimes.latency = latency;
StimTimes.variation = variation;
StimTimes.source = source;

end