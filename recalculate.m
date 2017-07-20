function recalculate(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    whichElectrodes, plotFigures, plotLFP, summaryFig, sourceFormat)
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
    whichElectrodes = [];
end
if nargin < 7 || isempty(plotFigures)
    plotFigures = 1;
end
if nargin < 8 || isempty(plotLFP)
    plotLFP = 0;
end
if nargin < 9 || isempty(summaryFig)
    summaryFig = 0;
end
if nargin < 10 || isempty(sourceFormat)
    sourceFormat = [];
end

% Duration log file
durationLogFile = 'duration_log.mat';
avgDur = 30; % assume 30 seconds per file
try
    if exist(durationLogFile,'file')
        load(durationLogFile);
    else
        save(durationLogFile, 'avgDur');
    end
catch
end

smoothing = 0.2;

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*', whichFiles);
nFiles = size(Files,1);

% Recalculate all files
if nFiles < 1
    return;
elseif nFiles > 1
    pool = gcp('nocreate');
    if ~summaryFig && isempty(pool) && isempty(getCurrentTask())
        parpool; % start the parallel pool
    end
    
    % Display some info about duration
    timeRemaining = avgDur * nFiles / min(nFiles, pool.NumWorkers);
    fprintf('There are %d files to be recalculated.\n', nFiles);
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));
    
    tic;
    parfor f = 1:size(Files,1)
        fileDuration(f) = recalculateSingle(dataDir, figuresDir, animalID, ...
            Files.unit{f}, Files.fileName{f}, sourceFormat, whichElectrodes, ...
            summaryFig, plotLFP, plotFigures, false);
    end
    elapsedTime = toc;
    avgDur = smoothing * mean(fileDuration) + (1 - smoothing) * avgDur;
else
    
    % Display some info about duration
    timeRemaining = avgDur;
    disp('There is 1 file to be recalculated.');
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));
    
    fileDuration = recalculateSingle(dataDir, figuresDir, animalID, ...
        Files.unit{1}, Files.fileName{1}, sourceFormat, whichElectrodes, ...
        summaryFig, plotLFP, plotFigures, true);
    
    elapsedTime = fileDuration;
    avgDur = smoothing * fileDuration + (1 - smoothing) * avgDur;
end
save(durationLogFile, 'avgDur');
fprintf('Total elapsed time: %d minutes and %d seconds\n', ...
    floor(elapsedTime/60), floor(rem(elapsedTime,60)));

