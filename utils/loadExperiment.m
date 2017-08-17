function [dataset] = loadExperiment(dataDir, animalID, fileNo, sourceFormat)

if nargin < 4 || isempty(sourceFormat)
    sourceFormat = {'Plexon', 'Ripple'};
elseif ~iscell(sourceFormat)
    sourceFormat = cellstr(sourceFormat);
end

dataset = [];

[~, ~, Files] = findFiles(dataDir, animalID, [], '*.mat', fileNo);
if size(Files, 1) > 1
    warning('Too many files with the same file number (#%d)', fileNo);
    return;
elseif isempty(Files)
    warning('File no %d not found', fileNo);
    return;
end
filePath = Files.rawFileName{1};

% Load the file
if ~exist(filePath, 'file')
    warning('No data for file %d', fileNo);
    return;
end
try
    file = load(filePath, 'dataset');
catch e
    warning('Possibly corrupt dataset (file #%d)', fileNo);
    return;
end
    
% Pick which data to load
whichData = [];
i = 1;
while isempty(whichData)
    if i > length(sourceFormat)
        warning('No dataset for %s', char(sourceFormat));
        return;
    end
    whichData = find(strcmp({file.dataset.sourceformat}, sourceFormat{i}), ...
        1, 'last');
    i = i + 1;
end
dataset = file.dataset(:,whichData);
if ~isfield(dataset, 'filepath') || isempty(dataset.filepath)
    dataset.filepath = filePath;
end

% Check data
if ~isfield(dataset,'spike')
    warning('No spikes for file %d', fileNo);
end
% Check params
if ~isfield(dataset,'ex') || ~isfield(dataset.ex, 'Data') ...
        || isempty(dataset.ex.Data)
    warning('Missing Params for file %d', fileNo);
end
% % Check LFP
% if ~isfield(dataset,'lfp')
%     warning('No LFP for file %d', fileNo);
% end
% % Check Analog
% if ~isfield(dataset,'analog1k')
%     warning('No analog data for file %d', fileNo);
% end
% % Check Events
% if ~isfield(dataset,'digital')
%     warning('No digital events for file %d', fileNo);
% end

end