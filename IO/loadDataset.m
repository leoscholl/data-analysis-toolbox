function [dataset] = loadDataset(filePath, spikeFormat, fields)

dataset = [];
if ~exist('spikeFormat', 'var') || isempty(spikeFormat)
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
    file = matfile(filePath);
catch e
    warning('Possibly corrupt dataset (%s)\n%s', filePath, ...
        getReport(e,'basic','hyperlinks','off'));
    return;
end
    
% Load wanted non-spike fields
if ~exist('fields', 'var') || isempty(fields)
    fields = fieldnames(file);
end
nonSpikeFields = {'digital', 'lfp', 'analog1k', 'analog30k', 'source', ...
    'secondperunit', 'sourceformat', 'ex', 'filepath'};
for f = 1:length(nonSpikeFields)
    if ismember(nonSpikeFields{f}, fields)
        dataset.(nonSpikeFields{f}) = file.(nonSpikeFields{f});
    end
end

% Load spike field
spikeFields = setdiff(fieldnames(file), nonSpikeFields);
spikeFormat = strcat(lower(spikeFormat),'spike');
if ismember(spikeFormat, spikeFields)
    dataset.spike = file.(spikeFormat);
    dataset.spikeformat = spikeFormat;
else
    warning('No spikes were found of the format %s', spikeFormat);
    dataset.spike = [];
    dataset.spikeformat = 'spike';
end

% Check params
if ~isfield(dataset,'ex')
    warning('Missing experimental data for %s', filePath);
end

end