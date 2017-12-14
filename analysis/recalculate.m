function recalculate(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    searchString, plotFigures, plotLFP, isparallel, sourceFormat)
%recalculate and replot all data
% whichUnits is an array of unit numbers to calculate
% whichFiles is an array of file numbers to calculate

% Default parameters
if nargin < 4
    whichUnits = [];
end
if nargin < 5
    whichFiles = [];
end
if nargin < 6
    searchString = '*';
end
if nargin < 7 || isempty(plotFigures)
    plotFigures = true;
end
if nargin < 8 || isempty(plotLFP)
    plotLFP = false;
end
if nargin < 9 || isempty(isparallel)
    isparallel = true;
end
if nargin < 10 || isempty(sourceFormat)
    sourceFormat = [];
end

% Duration preference
avgDur = 30; % assume 30 seconds per file
if ispref('data_analysis_toolbox','avgRecalculateDuration')
    avgDur = getpref('data_analysis_toolbox','avgRecalculateDuration');
end

smoothing = 0.2;

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, searchString, whichFiles);
nFiles = size(Files,1);

% Recalculate all files
if nFiles < 1
    return;
elseif nFiles > 1
    pool = gcp('nocreate');
    if isempty(pool) && isempty(getCurrentTask())
        pool = parpool; % start the parallel pool
    end
    
    % Display some info about duration
    timeRemaining = avgDur * nFiles / min(nFiles, pool.NumWorkers);
    fprintf('There are %d files to be recalculated.\n', nFiles);
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));

    tic;
    fileDuration = [];
    if isparallel
        parfor f = 1:size(Files,1)
            dataset = loadExperiment(dataDir, animalID, Files.fileNo(f), sourceFormat);
            if isempty(dataset)
                continue; % doesn't exist
            end
            result = recalculateSingle(dataset, figuresDir, [], ...
                plotLFP, plotFigures, false, false);
            fileDuration(f) = result.fileDuration;
        end
    else
        for f = 1:size(Files,1)
            dataset = loadExperiment(dataDir, animalID, Files.fileNo(f), sourceFormat);
            if isempty(dataset)
                continue; % doesn't exist
            end
            result = recalculateSingle(dataset, figuresDir, [], ...
                plotLFP, plotFigures, false, false);
            fileDuration(f) = result.fileDuration;
        end
    end
    elapsedTime = toc;
    avgDur = sum(fileDuration .* smoothing .* ...
        ((1 - smoothing).^((1:length(fileDuration)) - 1))) + ...
        avgDur .* (1 - smoothing) .^ length(fileDuration);
else
    
    % Display some info about duration
    timeRemaining = avgDur;
    disp('There is 1 file to be recalculated.');
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));
    
    dataset = loadExperiment(dataDir, animalID, Files.fileNo(1), sourceFormat);
    if isempty(dataset)
        return; % doesn't exist
    end
    result = recalculateSingle(dataset, figuresDir, searchString, ...
        plotLFP, plotFigures, isparallel, true);
    fileDuration = result.fileDuration;
    
    elapsedTime = fileDuration;
    avgDur = smoothing * fileDuration + (1 - smoothing) * avgDur;
end
setpref('data_analysis_toolbox', 'avgRecalculateDuration', avgDur);
fprintf('Total elapsed time: %d minutes and %d seconds\n\n', ...
    floor(elapsedTime/60), floor(rem(elapsedTime,60)));

