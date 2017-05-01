function MoveSpikeFiles (DataDir, DestDir, AnimalID, WhichUnits, FileType, Split)
% MoveSpikeFiles
%
% Split:
% 0 - move the merged spike file
% 1 - move the split spike files
% 2 - move all files
%

if nargin < 6
    Split = 1;
end
if nargin < 5
    FileType='bin';
end
if nargin < 4
    WhichUnits = [];
end

if isempty(WhichUnits)
    return;
end

Units = FindUnits(DataDir, AnimalID, WhichUnits);
if size(Units, 1) < length(WhichUnits)
    Units = FindUnits(DestDir, AnimalID, WhichUnits);
end
%ExpName = '[Ori]'

%%
disp('moving files...')
for un = 1:length(Units(:,1))
       
    Unit = deblank(Units(un,:));
    
    if Split
        FileName = '*]-spikes.mat';
    else
        switch FileType
            case 'osort'
                FileName = '*-osort-spikes.mat';
            otherwise
                FileName = [AnimalID, Unit, '-spikes.mat'];
        end
    end
    if Split > 1
        FileName = '*-spikes.mat';
    end

    % copy spike files
    DataPath = fullfile(DataDir, AnimalID, Unit, FileName);
    DestPath = fullfile(DestDir, AnimalID, Unit);
    
    if copyfile(DataPath,DestPath)
        disp(DataPath)
    end
    
    DataPath = fullfile(DataDir, AnimalID, FileName);
    DestPath = fullfile(DestDir, AnimalID, Unit);
    
    if copyfile(DataPath,DestPath)
        disp(DataPath)
    end
end

disp('...done')
