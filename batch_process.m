function [results] = batch_process(files, figuresPath, isParallel, ...
    spikeFormat, actions, verbose, varargin)
%batch_process process multiple files
%   Detailed explanation goes here

if ~exist('verbose', 'var') || isempty(verbose)
    verbose = false;
end

if ~exist('actions', 'var') || isempty(actions)
    actions = {};
end

results = struct('source', cell(0), 'status', cell(0), ...
    'result', cell(0), 'error', cell(0));

if iscell(files) 
    if length(files) == 1
        files = files{1};
    elseif isParallel
        parfor i = 1:length(files)
            results(i) = batch_process(files{i}, figuresPath, false, ...
                spikeFormat, actions, verbose, varargin{:});
        end
        return;
    else
        for i = 1:length(files)
            results(i) = batch_process(files{i}, figuresPath, false, ...
                spikeFormat, actions, verbose, varargin{:});
        end
        return;
    end
end

results = [];
results.source = files;
results.status = 0;
results.result = [];
results.error = [];

% Load from file
dataset = loadDataset(files, spikeFormat);
if isempty(dataset)
    if verbose
        fprintf('Dataset empty: %s\n', files);
    end
    results.error = 'Empty dataset';
    return;
end

% Dispatch to the appropriate process
try
    if contains(actions, 'dispatch')
        actions = union(setdiff(actions, 'dispatch'), ...
            defaultActions(dataset.ex));
    end
    results.result = processData(dataset, figuresPath, actions, ...
        false, varargin{:});    results.status = 1;

catch e
    warning('Error in dataset %s\n%s', files, ...
        getReport(e,'basic','hyperlinks','off'));
    results.error = e;
end

end

