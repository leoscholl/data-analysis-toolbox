% Unsorted recalculation

DataDir = 'I:\Data\';
ResultsDir = 'I:\Results\unsorted\';
AnimalID = 'R1701';
Units = [2:11];

Recalculate(DataDir,ResultsDir,AnimalID,Units)

%% Parameters

% Maintenance variables
DataDir = 'I:\Data\';
ResultsDir = 'I:\Results\osort\';
NetworkDir = 'Z:\Unsorted_LP_Rat';
LogFilename = 'sorting_log.txt';
Log = fopen(LogFilename, 'a+t');

% Experiment info
% Animals = {'R1518', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
%     'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629'};
% Units = {[1:5], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
%     [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13]};

FileType = 'osort'; % bin, osort, unsorted

Animals = {'R1701'};
Units = {[2:11]};

%% Start logging
fprintf(Log, '\n=================\n%s\n=================\nPreparing run...\n', ...
    datestr(now));
for i = 1:length(Animals)
    AnimalID = Animals{i};
    WhichUnits = Units{i};
    fprintf(Log, '%s\t%s\n', AnimalID, mat2str(WhichUnits));
end

%% Set path for O-sort
SetOsortPath

%% Begin run
for i = 1:length(Animals)
    
    AnimalID = Animals{i};
    WhichUnits = Units{i};

    % Open the case file
    CaseFile = fullfile(DataDir, AnimalID, [AnimalID,'.mat']);
    if exist(CaseFile,'file')
        load(CaseFile);
        WhichUnits = setdiff(WhichUnits, SortedUnits);
    else
        SortedUnits = [];
        save(CaseFile,'SortedUnits');
    end
    NewSortedUnits = [];
    
    % Make a log
    fprintf(Log, '------------------\nRun #%i: %s\n------------------\n', i, AnimalID);
        
    if isempty(WhichUnits)
        fprintf(Log, 'All units already sorted for %s. Abort.\n', AnimalID);
        continue;
    else
        fprintf(Log, 'Running units %s...\n', mat2str(WhichUnits));
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

        MakeFilesForSorting(DataDir,AnimalID,WhichUnits,FileType);
        fprintf(Log, 'Converted files for sorting...\n');
%         
        %% Move files from network drive
        %         MoveSpikeFiles(NetworkDir, DataDir, AnimalID, WhichUnits, FileType, 0);
        %     fprintf(Log, 'Moved files to network drive...\n');
        
        %% Do sorting?
        switch FileType
            case 'osort'
                fprintf(Log, 'Attempting automatic sorting with OSort...\n')
                for UnitNo = WhichUnits
                    try
                        
                        clear filenames original_filename
                        
                        % Sorting
                        fprintf(Log, 'Unit %i...', UnitNo);
                        [filenames, original_filename] = ...
                            OSort_script(DataDir, AnimalID, UnitNo);
                        fprintf(Log, 'sorted...');

                        if ~isempty(filenames)
                            % Converting
                            ConvertOSortSpikes(DataDir, AnimalID, UnitNo, filenames);
                            fprintf(Log, 'and converted. done.\n');

                            % Keep track
                            NewSortedUnits = union(NewSortedUnits, UnitNo);
                        end
                        
                    catch e
                        
                        % Ignore errors, but print them out for debugging...
                        Report = getReport(e,'extended','hyperlinks','off');
                        warning(Report,'Error');
                        fprintf(Log, '\n\n%s\n', Report);
                    end
                end
      
            case 'unsorted'
                fprintf(Log, 'No sorting. Just recalculate...\n');
                
                % Convert ripple spikes into matlab format
                ConvertRippleSpikes(DataDir, AnimalID, WhichUnits);
                fprintf(Log, 'Converted ripple spikes to matlab format.\n');
                
                NewSortedUnits = WhichUnits;
                
            case 'bin'
                fprintf(Log, 'Files sorted manually.\n');
                
                % Split the sorted unit into individual files
                SplitMergedFiles(DataDir, AnimalID, WhichUnits, '-spikes');
                fprintf(Log, 'Cut up spikes into separate files.\n');
                
                NewSortedUnits = WhichUnits;
        end
        
        % Move the spike files to the copy dir
%         MoveSpikeFiles(DataDir, ResultsDir, AnimalID, NewSortedUnits, 2);
%         fprintf(Log, 'Copied the spike files...\n');
        
        %% Recalculate
        Recalculate(DataDir, ResultsDir, AnimalID, NewSortedUnits);
        fprintf(Log, 'And recalculated all files for %s\n', AnimalID);
        
        % Save the case file
        SortedUnits = union(SortedUnits, NewSortedUnits);
        save(CaseFile,'SortedUnits','-append');
      
    catch e
        
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
        fprintf(Log, '\n\n%s\n', Report);
        
        % Save the case file
        SortedUnits = union(SortedUnits, NewSortedUnits);
        save(CaseFile,'SortedUnits','-append');
    end
    
    fprintf(Log,'End of run\n');
    
end

fprintf(Log, 'End of all runs\n\n');
fclose(Log);
