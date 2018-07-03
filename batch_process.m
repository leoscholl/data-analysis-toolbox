function [results] = batch_process(files, figuresPath, mt, isParallel, ...
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
            results(i) = batch_process(files{i}, figuresPath, mt, false, ...
                spikeFormat, actions, verbose, varargin{:});
        end
        return;
    else
        for i = 1:length(files)
            results(i) = batch_process(files{i}, figuresPath, mt, false, ...
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

if verbose
    fprintf('Processing dataset:    %s\n', files);
end

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
    
    if ~isempty(mt) && ...
            ~isempty(results.result) && ...
            isfield(results.result, 'spike')
        units = results.result.spike;
        for u = 1:length(units)
            test = units(u);
            test.sourceformat = 'Result';
            test.(dataset.ex.ID){1}.groups = results.result.groups;
            mt.addRow(test);
        end
    end

catch e
    fprintf(2,'Error in dataset %s\n%s\n', files, ...
        getReport(e,'basic','hyperlinks','off'));
    for i = 1:length(e.stack)
        fprintf(2, 'in file %s line %d\n', e.stack(i).name, e.stack(i).line);
    end
    results.error = e;
end

end

