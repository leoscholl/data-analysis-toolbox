% Maintenance variables
DataDir = 'I:\Data\';
DestDir = 'Y:\Unsorted_LP_Rat';

% Experiment info
Animals = {'R1518', 'R1519', 'R1520', 'R1521', 'R1522', 'R1524', 'R1525', 'R1526', ...
    'R1527', 'R1528', 'R1536', 'R1601', 'R1603', 'R1604', 'R1605', 'R1629'};
AllUnits = {[1:5], [1:4], [1:8,10:16], [1:2,4:7,10:12], [1:5], [4:12], [2:3], [7:9, 11:20], ...
    [3], [3:9], [1:19], [1:7], [1:16], [1:13], [1:9], [1:13]};
    
FileType = 'bin'; % bin, osort, unsorted

% Animals = {'R1521'};
% Units = {[1:2,4:7]};

tic;

for i = 1:length(Animals)
    
    AnimalID = Animals{i};
    WhichUnits = AllUnits{i};

    % Begin
    try
        % Prepare the files
        MakeFilesForSorting(DataDir,AnimalID,WhichUnits,FileType);
        
        % Move the files
        Units = FindUnits(DataDir, AnimalID, WhichUnits);

        disp('moving files...')
        if isempty(Units)
            continue;
        end
        for un = 1:length(Units(:,1))
            
            Unit = deblank(Units(un,:));
            DestPath = fullfile(DestDir, AnimalID);
            if ~exist(DestPath,'dir')
                mkdir(DestPath);
            end

            % Raw bin files
            DataPath = fullfile(DataDir, AnimalID, Unit, 'raw');
            SearchString = [AnimalID, Unit, '.bin'];
            CopyFiles (SearchString, DataPath, DestPath)
            
            % Matlab header files
            DataPath = fullfile(DataDir, AnimalID, Unit);
            SearchString = [AnimalID, Unit, '.mat'];
            CopyFiles (SearchString, DataPath, DestPath)

        end
    
    catch e 
        % Ignore errors, but print them out for debugging...
        Report = getReport(e,'extended','hyperlinks','off');
        warning(Report,'Error');
    end 
end

toc;
