%% Parameters

% Maintenance variables
rawDataDir = 'I:\Data\';
dataDir = 'I:\DataExport';
sourceFormat = {'Ripple'};
figuresDir = 'I:\Figures\unsorted';
isParallel = 1;

logFilename = 'sorting_log.txt';
log = fopen(logFilename, 'a+t');
diaryFilename = 'sorting_output.txt';
diary(diaryFilename);

% Plotting parameters
plotFigures = 0; % overrides everything else
plotLFP = 0;
summaryFig = 0; % faster without summary figs (can't do parallel pool)
overwrite = 0; % for exporting data

% Experiment info  
% animals = {'R1518', 'R1520', 'R1521',
animals = {'R1522', ...
    'R1524', 'R1525', 'R1526', 'R1527', ...
    'R1528', 'R1536', 'R1601', 'R1603', ...
    'R1604', 'R1605', 'R1629', 'R1701', ...
    'R1702' };
% units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], 
units = {[1:5], ...
    [4:12], [2:3], [7:9, 11:20], [3], ...
    [3:9], [1:19], [1:7], [1:16], ...
    [1:13], [1:9], [1:13], [2:11], ...
    [1:9]};
% 
% animals = {'R1521', 'R1536'};
% units = {[1:2,4:7,10:12], [1:19]};

fileType = 'unsorted'; % bin, osort, unsorted

%% Start logging
fprintf(log, '\n=================\n%s\n=================\nPreparing run...\n', ...
    datestr(now));
for a = 1:length(animals)
    animalID = animals{a};
    whichUnits = units{a};
    fprintf(log, '%s\t%s\n', animalID, mat2str(whichUnits));
end

%% Set path for O-sort
%SetOsortPath

%% Begin run
for a = 1:length(animals)
    
    animalID = animals{a};
    whichUnits = units{a};
    [~, ~, Files] = findFiles(dataDir, animalID, whichUnits, '*.mat');

    % Make a log
    fprintf(log, '------------------\nRun #%i: %s\n------------------\n', a, animalID);
        
    if isempty(whichUnits)
        fprintf(log, 'All units already sorted for %s. Abort.\n', animalID);
        continue;
    else
        fprintf(log, 'Running units %s...\n', mat2str(whichUnits));
    end
    
    if isParallel
        
        if ~summaryFig && isempty(gcp('nocreate'))
            parpool; % start the parallel pool
        end
        
        parLog = cell(size(Files,1),1);
        parfor f=1:size(Files,1)
            fileNo = Files.fileNo(f);
            try
                whichElectrodes = [];
                recalculate(dataDir, figuresDir, animalID, whichUnits, fileNo, ...
                    whichElectrodes, plotFigures, plotLFP, summaryFig)
                parLog{f} = sprintf('%s\n', Files.fileName{f});
            catch e
                % Ignore errors, but print them out for debugging...
                Report = getReport(e,'extended','hyperlinks','off');
                warning(Report,'Error');
                parLog{f} = sprintf('\n\nError for file %s:\n%s\n', ...
                    Files.fileName{f}, Report);
            end
        end
        cellfun(@(x)fprintf(log, '%s', x), parLog);
    else
        for f=1:size(Files,1)
            fileNo = Files.fileNo(f);
            try
                whichElectrodes = [];
                recalculate(dataDir, figuresDir, animalID, whichUnits, fileNo, ...
                    whichElectrodes, plotFigures, plotLFP, summaryFig, sourceFormat)
                fprintf(log, '%s\n', Files.fileName{f});
            catch e
                % Ignore errors, but print them out for debugging...
                Report = getReport(e,'extended','hyperlinks','off');
                fprintf(log, '\n\nError for file %s\n', Files.fileName{f});
                warning(Report,'Error');
                fprintf(log, '%s\n', Report);
            end
        end
    end
    
    fprintf(log,'End of run\n');
    
end

fprintf(log, 'End of all runs\n\n');
fclose(log);
diary off

