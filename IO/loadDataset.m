function [dataset] = loadDataset(filePath, spikeFormat)

dataset = [];
if nargin < 2 || isempty(spikeFormat)
    spikeFormat = '';
end
if strcmp(spikeFormat, 'Ripple')
    spikeFormat = '';
end

% Load the file
if ~exist(filePath, 'file')
    warning('No data for %s', filePath);
    return;
end
try
    file = load(filePath);
catch e
    warning('Possibly corrupt dataset (%s)\n%s', filePath, ...
        getReport(e,'basic','hyperlinks','off'));
    return;
end
if ~isfield(file, 'dataset')
    warning('No dataset for %s', filePath);
    return;
end
    
% Pick which spikes to load
fields = {'digital', 'lfp', 'analog1k', 'analog30k', 'source', ...
    'secondperunit', 'sourceformat', 'ex', 'filepath'};
spikeFields = setdiff(fieldnames(file.dataset), fields);
dataset = rmfield(file.dataset, spikeFields);
spikeFormat = strcat(lower(spikeFormat),'spike');
if ismember(spikeFormat, spikeFields)
    dataset.spike = file.dataset.(spikeFormat);
    dataset.spikeformat = spikeFormat;
else
    warning('No spikes were found of the format %s', spikeFormat);
    dataset.spike = file.dataset.spike;
    dataset.spikeformat = 'spike';
end

% Check params
if ~isfield(dataset,'ex')
    warning('Missing experimental data for %s', filePath);
end

end