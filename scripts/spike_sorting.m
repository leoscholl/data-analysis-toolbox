%% Parameters

% Maintenance variables
DataDir = 'I:\Data\';
CopyDir = 'I:\Copy - osort\Data\';
NetworkDir = 'Z:\Data\';
LogFilename = 'sorting_log.txt';

% Experiment info
AnimalID = 'C1611';
WhichUnits = [15];

FileType = 'osort'; % bin, osort, unsorted

% Animals = {'R1521'};
% Units = {[1:2,4:7]};

%% Start logging
% Open the log
Log = fopen(LogFilename, 'a+t');
fprintf(Log, '\n=================\n%s\n%s\n=================', ...
    datestr(now), AnimalID);


%% Set path for O-sort
SetOsortPath

%% Begin run
NewSortedUnits = [];
try
    %         MoveFitFiles(DataDir, CopyDir, AnimalID, WhichUnits); % copy old files
    %         fprintf(Log, 'Copied fit files...\n');
    
    MakeFilesForSorting(DataDir,AnimalID,WhichUnits,FileType);
    fprintf(Log, 'Converted files for sorting...\n');
    %
    %% Move files from network drive
    %     MoveSpikeFiles(NetworkDir, DataDir, AnimalID, WhichUnits, FileType, 0);
    %     fprintf(Log, 'Moved files to network drive...\n');
    
    %% Do sorting?
    switch FileType
        case 'osort'
            fprintf(Log, 'Attempting automatic sorting with OSort...\n');
            for UnitNo = WhichUnits
                try
                    
                    clear filenames original_filename Channels
                    
                    Channels = 22;
                    
                    % Sorting
                    fprintf(Log, 'Unit %i...', UnitNo);
                    [filenames, original_filename] = ...
                        OSort_script(DataDir, AnimalID, UnitNo, Channels);
                    if ~isempty(filenames)
                        fprintf(Log, 'sorted...');
                        
                        % Converting
                        ConvertOSortSpikes(DataDir, AnimalID, UnitNo, filenames);
                        fprintf(Log, 'and converted. done.\n');
                        
                        % Keep track
                        NewSortedUnits = union(NewSortedUnits, UnitNo);
                    else
                        fprintf(Log, 'could not be sorted.\n');
                    end
                    
                catch e
                    
                    % Ignore errors, but print them out for debugging...
                    Report = getReport(e,'extended','hyperlinks','off');
                    warning(Report,'Error');
                    fprintf(Log, '\n\n%s\n', Report);
                end
            end
            
            % Split the sorted unit into individual files
            SplitMergedFiles(DataDir, AnimalID, NewSortedUnits, '-osort-spikes');
            fprintf(Log, 'Cut up spikes into separate files.\n');
            
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
    
    %% Recalculate
    RecalculateAllLeo(DataDir, AnimalID, NewSortedUnits);
    fprintf(Log, 'And recalculated all files for %s\n', AnimalID);
    
    % Copy figures
    MoveFitFiles(DataDir, CopyDir, AnimalID, NewSortedUnits);
    fprintf(Log, 'And copied those figures\n');
    
catch e
    
    % Ignore errors, but print them out for debugging...
    Report = getReport(e,'extended','hyperlinks','off');
    warning(Report,'Error');
    fprintf(Log, '\n\n%s\n', Report);
    
    % Save the case file
    %         SortedUnits = union(SortedUnits, NewSortedUnits);
    %         save(CaseFile,'SortedUnits','-append');
    
    
end

fprintf(Log, 'End of run\n\n');
fclose(Log);
