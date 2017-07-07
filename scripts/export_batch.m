%% Parameters

% Maintenance variables
rawDataDir = '\\Studentlyonlab\f\Data';
dataDir = 'I:\DataExport';

logFilename = 'batch_log.txt';
log = fopen(logFilename, 'a+t');
diaryFilename = 'batch_output.txt';
diary(diaryFilename);

% Plotting parameters
plotFigures = 0; % overrides everything else
plotLFP = 0;
plotWFs = 1;
summaryFig = 0; % faster without summary figs (can't do parallel pool)
overwrite = 0; % for exporting data

% % Experiment info  
% animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
%     'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629', ...
%     'R1701', 'R1702' };
% units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
%         [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13], [2:11], [1:9]};

animals = {'C1611'};
units = {[18]};

fileType = 'unsorted'; % bin, osort, unsorted

%% Start logging
fprintf(log, '\n=================\n%s\n=================\nPreparing run...\n', ...
    datestr(now));
for i = 1:length(animals)
    animalID = animals{i};
    whichUnits = units{i};
    fprintf(log, '%s\t%s\n', animalID, mat2str(whichUnits));
end

%% Set path for O-sort
%SetOsortPath

%% Begin run
for i = 1:length(animals)
    
    animalID = animals{i};
    whichUnits = units{i};
    whichFiles = [];

    % Make a log
    fprintf(log, '------------------\nRun #%i: %s\n------------------\n', i, animalID);
    fprintf(log, 'Running units %s...\n', mat2str(whichUnits));
    
    % Begin
    try

        %% Do sorting?
        switch fileType
            case 'osort'
                fprintf(log, 'Attempting automatic sorting with OSort...\n');
                for unitNo = whichUnits
                    try
                        
                        clear filenames original_filename
                        
                        % Sorting
                        fprintf(log, 'Unit %i...', unitNo);
                        [filenames, original_filename] = ...
                            OSort_script(dataDir, animalID, unitNo);
                        fprintf(log, 'sorted...');

                        if ~isempty(filenames)
                            % Converting
                            ConvertOSortSpikes(dataDir, animalID, unitNo, filenames);
                            fprintf(log, 'and converted. done.\n');
                        end
                        
                    catch e
                        
                        % Ignore errors, but print them out for debugging...
                        Report = getReport(e,'extended','hyperlinks','off');
                        warning(Report,'Error');
                        fprintf(log, '\n\n%s\n', Report);
                    end
                end
      
            case 'unsorted'
                fprintf(log, 'No sorting. Just recalculate...\n');
                
                % Convert ripple spikes into matlab format
                dataExportNA( rawDataDir, dataDir, animalID, whichUnits, ...
                    whichFiles, overwrite);
                
            case 'bin'
                fprintf(log, 'Files sorted manually.\n');
                
                % Split the sorted unit into individual files
                SplitMergedFiles(dataDir, animalID, whichUnits, '-spikes');
                fprintf(log, 'Cut up spikes into separate files.\n');
        end

%         %% Calculations and Plotting
%         whichElectrodes = [];
%         recalculate(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
%             whichElectrodes, plotFigures, plotLFP, summaryFig)
%         fprintf(log, 'And recalculated all files for %s\n', animalID);

    catch e
        
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
        fprintf(log, '\n\n%s\n', Report);
    end
    
    fprintf(log,'End of run\n');
    
end

fprintf(log, 'End of all runs\n\n');
fclose(log);
diary off
