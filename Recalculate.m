function recalculate(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    whichElectrodes, showFigures, plotLFP, summaryFig)
%recalculate and replot all data
% whichUnits is an array of unit numbers to calculate
% whichFiles is an array of file numbers to calculate

% addpath('C:\Program Files (x86)\Ripple\Trellis\Tools\neuroshare\');
tic;

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
if nargin < 7 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 8 || isempty(plotLFP)
    plotLFP = 0;
end
if nargin < 9 || isempty(summaryFig)
    summaryFig = 0;
end

% Duration log file
DurationLogFile = 'duration_log.mat';
if ~exist('avgDur')
    avgDur = 30; % assume 30 seconds per file
end
if exist(DurationLogFile,'file')
    load(DurationLogFile);
else
    save(DurationLogFile, 'avgDur');
end
smoothing = 0.2;

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*', whichFiles);

% Display some info about duration
nFiles = size(Files,1);
progress = 0;
elapsedTime = 0;
timeRemaining = avgDur * (nFiles - progress);
fprintf('There are %d files to be recalculated.\n', nFiles);
fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
    floor(timeRemaining/60), floor(rem(timeRemaining,60)));

if nFiles < 1
    return;
end

% Recalculate all files
for f = 1:size(Files,1)
    
    tic; % start the clock
    
    % Data comes from the DataDir, results go into the ResultsDir
    unit = Files.unit{f};
    dataPath = fullfile(dataDir,animalID,unit,filesep);
    figuresPath = fullfile(figuresDir,animalID,unit,filesep);
    
    clear hasError Electrodes Paams StimTimes LFP AnalogIn
    fileName = Files.fileName{f};
    disp(fileName);
%     
%     try
%         
        % Load experiment
        disp('Loading experiment files...');
        [Electrodes, Params, StimTimes, LFP, AnalogIn, hasError, errorMsg] = ...
            loadExperiment(dataDir, animalID, unit, fileName);
        
        if hasError
            plotStimTimes(StimTimes, AnalogIn, figuresPath, fileName, errorMsg);
        end

        
        if hasError > 1
            warning('Loading experiment failed. Skipping.');
            continue;
        end

        % Number of bins or size of bins?
        switch Params.stimType
            case {'VelocityConstantCycles', 'VelocityConstantCyclesBar',...
                    'Looming', 'ConstantCycles'}
                Params.binType = 'number'; % constant number of bins
            otherwise
                Params.binType = 'size'; % constant size of bins (for F1)
        end
        
        % What to plot?
        switch Params.stimType
            case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                    'NaturalImages', 'NaturalVideos'}
                plotMaps = 0;
                plotTCs = 0;
                plotBars = 1;
                plotRasters = 1;
                if strcmp(animalID, 'R1702')
                    plotWFs = 0;
                else
                    plotWFs = 1;
                end
                plotISI = 1;
            case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                plotMaps = 1;
                plotTCs = 0;
                plotBars = 0;
                plotRasters = 1;
                plotWFs = 0;
                plotISI = 0;
            otherwise
                plotMaps = 0;
                plotTCs = 1;
                plotBars = 0;
                plotRasters = 1;
                plotWFs = 0;
                plotISI = 0;
        end
        
        
        % Do the analysis / plotting
        switch Params.stimType
            case {'OriLowHighTwoApertures', 'CenterNearSurround'}
                fprintf(2, 'Center surround not yet implemented.\n');
            otherwise
                
                if ~summaryFig && isempty(gcp('nocreate'))
                    parpool; % start the parallel pool
                end
                
                % Binning and making rastergrams
                disp('analyzing...');
                [Params, Results] = analyze(dataPath, fileName, ...
                    Params, StimTimes, Electrodes, whichElectrodes);
                
                % Plotting tuning curves and maps
                disp('plotting...');
                plotAllResults(figuresPath, fileName, Params, Results, ...
                    whichElectrodes, plotTCs, plotBars, plotRasters, ...
                    plotMaps, summaryFig, plotLFP, showFigures);
                
                % Plot waveforms?
                if plotWFs
                    disp('Plotting waveforms...');
                    plotWaveforms(dataPath, figuresPath, fileName, Electrodes);
                end
                
                % Plot ISIs?
                if plotISI && ~isempty(Results)
                    disp('Plotting ISIs...');
                    plotISIs(figuresPath, fileName, Results);
                end
        end
        
%     catch e
%         disp(['This file didnt work ',fileName])
%         warning(getReport(e,'extended','hyperlinks','off'),'Error');
%     end
    
    % Update duration log
    fileDuration = toc;
    progress = progress + 1;
    elapsedTime = elapsedTime + fileDuration;
    avgDur = smoothing * fileDuration + (1 - smoothing) * avgDur;
    save(DurationLogFile, 'avgDur');
    
    % Display time remaining
    fprintf('This file took %d minutes and %d seconds\n', ...
        floor(fileDuration/60), floor(rem(fileDuration,60)));
    timeRemaining = avgDur * (nFiles - progress);
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));
end


fprintf('Total elapsed time: %d minutes and %d seconds\n', ...
    floor(elapsedTime/60), floor(rem(elapsedTime,60)));

