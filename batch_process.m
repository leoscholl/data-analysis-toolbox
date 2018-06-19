function [results] = batch_process(files, figuresPath, isParallel, ...
    spikeFormat, plotFun, verbose, varargin)
%batch_process process multiple files
%   Detailed explanation goes here

if ~exist('verbose', 'var') || isempty(verbose)
    verbose = false;
end

if ~exist('plotFun', 'var') || isempty(plotFun)
    plotFun = {};
end

results = struct('source', cell(0), 'status', cell(0), ...
    'meta', cell(0), 'error', cell(0));

if iscell(files) 
    if length(files) == 1
        files = files{1};
    elseif isParallel
        parfor i = 1:length(files)
            results(i) = batch_process(files{i}, figuresPath, false, ...
                spikeFormat, plotFun, verbose, varargin{:});
        end
        return;
    else
        for i = 1:length(files)
            results(i) = batch_process(files{i}, figuresPath, false, ...
                spikeFormat, plotFun, verbose, varargin{:});
        end
        return;
    end
end

results = [];
results.source = files;
results.status = 0;
results.meta = [];
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
    results.meta = dispatch(dataset, figuresPath, isParallel, plotFun, varargin{:});
    results.status = 1;
catch e
    warning('Error in dataset %s\n%s', files, ...
        getReport(e,'basic','hyperlinks','off'));
    results.error = e;
end

end

