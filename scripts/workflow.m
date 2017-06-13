%% Parameters

% Maintenance variables
dataDir = 'I:\Data\';
resultsDir = 'I:\Results\unsorted\';
NetworkDir = 'Z:\Unsorted_LP_Rat';
logFilename = 'sorting_log.txt';
log = fopen(logFilename, 'a+t');
diaryFilename = 'sorting_output.txt';
diary(diaryFilename);

% Plotting parameters
plotLFP = 0;
plotWFs = 1;
summaryFig = 0; % faster without summary figs (can't do parallel pool)

% Experiment info 
% {'R1518', 
animals = {'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
    'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629', ...
    'R1701', 'R1702' };
% {[1:5], 
units = {[1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
    [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13], [2:11], [1:9]};

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

    % Open the case file
    caseFile = fullfile(dataDir, animalID, [animalID,'.mat']);
%     if exist(CaseFile,'file')
%         load(CaseFile);
%         WhichUnits = setdiff(WhichUnits, SortedUnits);
%     else
        sortedUnits = [];
        save(caseFile,'sortedUnits');
%     end
    newSortedUnits = [];
    
    % Make a log
    fprintf(log, '------------------\nRun #%i: %s\n------------------\n', i, animalID);
        
    if isempty(whichUnits)
        fprintf(log, 'All units already sorted for %s. Abort.\n', animalID);
        continue;
    else
        fprintf(log, 'Running units %s...\n', mat2str(whichUnits));
    end
    
%     % Find sorted files that aren't in the case file list
%     for UnitNo = WhichUnits
%         Unit = ['Unit',num2str(UnitNo)];
%         SpikesFile = fullfile(DataDir,AnimalID,Unit,[AnimalID,Unit,'-osort-spikes.mat']);
%         if exist(SpikesFile,'file')
%             NewSortedUnits = union(NewSortedUnits, UnitNo);
%             WhichUnits = setdiff(WhichUnits, UnitNo);
%         end
%     end

    % Begin
    try
%         MoveFitFiles(DataDir, CopyDir, AnimalID, WhichUnits); % copy old files
%         fprintf(Log, 'Copied fit files...\n');
%         DeleteFitFiles(DataDir, AnimalID, WhichUnits);
%         fprintf(Log, 'Deleting old fit files...\n');
% 
%         MakeFilesForSorting(DataDir,AnimalID,WhichUnits,FileType);
%         fprintf(Log, 'Converted files for sorting...\n');
%         
        %% Move files from network drive
        %         MoveSpikeFiles(NetworkDir, DataDir, AnimalID, WhichUnits, FileType, 0);
        %     fprintf(Log, 'Moved files to network drive...\n');
        
        %% Do sorting?
        switch fileType
            case 'osort'
                fprintf(log, 'Attempting automatic sorting with OSort...\n')
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

                            % Keep track
                            newSortedUnits = union(newSortedUnits, unitNo);
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
                dataExport( dataDir, [], animalID, whichUnits, [], 0);
                
            case 'bin'
                fprintf(log, 'Files sorted manually.\n');
                
                % Split the sorted unit into individual files
                SplitMergedFiles(dataDir, animalID, whichUnits, '-spikes');
                fprintf(log, 'Cut up spikes into separate files.\n');
                
                newSortedUnits = whichUnits;
        end
        
        % Move the spike files to the copy dir
%         MoveSpikeFiles(DataDir, ResultsDir, AnimalID, NewSortedUnits, 2);
%         fprintf(Log, 'Copied the spike files...\n');
        
        %% Recalculate
        recalculate(dataDir, resultsDir, animalID, whichUnits, [], ...
            [], [], plotLFP, summaryFig)
        fprintf(log, 'And recalculated all files for %s\n', animalID);
        
        % Save the case file
        sortedUnits = union(sortedUnits, newSortedUnits);
        save(caseFile,'sortedUnits','-append');
      
    catch e
        
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
        fprintf(log, '\n\n%s\n', Report);
        
        % Save the case file
        sortedUnits = union(sortedUnits, newSortedUnits);
        save(caseFile,'sortedUnits','-append');
    end
    
    fprintf(log,'End of run\n');
    
end

fprintf(log, 'End of all runs\n\n');
fclose(log);
diary off
