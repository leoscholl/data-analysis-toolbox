function recalculate(dataDir, resultsDir, animalID, whichUnits, whichFiles, ...
    whichElectrodes, showFigures, plotWaveforms, plotLFP, summaryFig)
%recalculate and replot all data
% whichUnits is an array of unit numbers to calculate
% whichFiles is an array of file numbers to calculate

close all;
addpath('conversion');
addpath('plotting');
addpath('utils');
addpath('export_fig_toolbox');
addpath('C:\Program Files (x86)\Ripple\Trellis\Tools\neuroshare\');
tic;

% Default parameters
if nargin < 4
    whichUnits = [];
end
if nargin < 5
    whichFiles = [];
end
if nargin < 6 || isempty(showFigures)
    showFigures = 0;
end
if nargin < 7
    whichElectrodes = [];
end
if nargin < 8 || isempty(plotWaveforms)
    plotWaveforms = 0;
end
if nargin < 9 || isempty(plotLFP)
    plotLFP = 0;
end
if nargin < 10 || isempty(summaryFig)
    summaryFig = 0;
end

% Duration log file
DurationLogFile = 'duration_log.mat';
if ~exist('AvgDur')
    avgDur = 30; % assume 30 seconds per file
end
if exist(DurationLogFile,'file')
    load(DurationLogFile);
else
    save(DurationLogFile, 'AvgDur');
end
smoothing = 0.05;

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*.nev', whichFiles);

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
    resultsPath = fullfile(resultsDir,animalID,unit,filesep);
    
    clear SpikeTimesMat StimTimes Waveforms StimType Params
    fileName = Files.fileName{f};
    disp(fileName);
    
%     try
        
        % Load experiment
        disp('Loading experiment files...');
        [Electrodes, Params, StimTimes, LFP, AnalogIn] = ...
            loadExperiment(dataDir, animalID, unit, fileName);
        
        % Plot waveforms?
        if plotWaveforms && ~isempty(Waveforms)
            disp('Loading waveforms...');
            Electrodes = loadRippleWaveforms(dataPath, fileName, Electrodes);
            disp('Plotting waveforms...');
            plotWaveforms(resultsPath, fileName, Electrodes);
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
            case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                plotMaps = 1;
                plotTCs = 0;
                plotBars = 0;
                plotRasters = 1;
            otherwise
                plotMaps = 0;
                plotTCs = 1;
                plotBars = 0;
                plotRasters = 1;
        end
        
        
        % Do the analysis / plotting
        switch Params.stimType
            case {'OriLowHighTwoApertures', 'CenterNearSurround'}
                fprintf(2, 'Center surround not yet implemented.\n');
            otherwise
                disp('analyzing...');
                [Params, Results] = analyze(resultsPath, fileName, ...
                    Params, StimTimes, Electrodes, whichElectrodes);
                disp('plotting...');
                plotAllResults(resultsPath, fileName, Params, Results, ...
                    whichElectrodes, plotTCs, plotBars, plotRasters, ...
                    plotMaps, summaryFig, plotLFP, showFigures);
        end
        
%     catch e
%         disp(['This file didnt work ',fileName])
%         warning(getReport(e,'extended','hyperlinks','off'),'Error');
%     end
    
    close all;
    
    % Update duration log
    fileDuration = toc;
    progress = progress + 1;
    elapsedTime = elapsedTime + fileDuration;
    avgDur = smoothing * fileDuration + (1 - smoothing) * avgDur;
    save(DurationLogFile, 'AvgDur', '-append');
    
    % Display time remaining
    fprintf('This file took %d minutes and %d seconds\n', ...
        floor(fileDuration/60), floor(rem(fileDuration,60)));
    timeRemaining = avgDur * (nFiles - progress);
    fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
        floor(timeRemaining/60), floor(rem(timeRemaining,60)));
end


fprintf('Total elapsed time: %d minutes and %d seconds\n', ...
    floor(elapsedTime/60), floor(rem(elapsedTime,60)));

