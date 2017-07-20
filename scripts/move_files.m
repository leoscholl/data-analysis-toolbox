disp('copying files...')

dataDir = 'I:\Figures\';
destDir = 'I:\Figures\';

animalIDs = findAnimals(dataDir);
% animalID = '';
whichUnits = [];

for a = 1:length(animalIDs)
    animalID = animalIDs{a};
    units = findUnits(dataDir, animalID, whichUnits);
    
    for i=1:length(units)
        unit = units{i};
    
    %% Delete direcories
    %     dataPath = fullfile(dataDir, animalID, unit);
    %     destPath = fullfile(destDir, animalID, unit, 'StimTimes');
    %     if exist(destPath, 'dir')
    %         rmdir(destPath, 's');
    %         disp(destPath);
    %     end
    
    %% Copy Files
    %     if ~exist(DestPath,'dir')
    %         mkdir(DestPath);
    %     end
    
    %% copy .ns5, .nev, and .mat files
    % CopyFiles('*].ns5', DataPath, DestPath);
    % CopyFiles('*].nev', DataPath, DestPath);
    % CopyFiles('*].mat', DataPath, DestPath);
    % CopyFiles('*-params.mat', DataPath, DestPath);
    % CopyFiles('*-spikes.mat', DataPath, DestPath);
    % CopyFiles('*.bin', DataPath, DestPath);
    % CopyFiles([AnimalID,Unit,'.mat'], DataPath, DestPath);
    
    %% copy bin files
    % DataPath = fullfile(DataDir, AnimalID, Unit, 'raw');
    % DestPath = fullfile(DestDir, AnimalID, Unit, 'raw');
    % if ~exist(DestPath,'dir')
    %     mkdir(DestPath);
    % end
    % CopyFiles('*.bin', DataPath, DestPath);
    % DataPath = fullfile(DataDir, AnimalID, Unit, 'osort');
    % DestPath = fullfile(DestDir, AnimalID, Unit, 'osort');
    % if ~exist(DestPath,'dir')
    %     mkdir(DestPath);
    % end
    % CopyFiles('*.bin', DataPath, DestPath);
    
    %% Copy sorted files
%     dataPath = fullfile(dataDir, animalID);
%     destPath = fullfile(destDir, animalID);
%     if ~exist(destPath,'dir')
%         mkdir(destPath);
%     end
%     copyFiles('*.mat', dataPath, destPath);
    
    %% Delete files
    %     delete(fullfile(dataPath,'*]-spikes.mat'));
    %     delete(fullfile(dataPath,'*]-params.mat'));
    %     delete(fullfile(dataPath,'*]-lfp.mat'));
    
    %% Move folders
        channels = dir(fullfile(dataDir, animalID, unit, 'Ch*'));
        channels = {channels([channels.isdir]).name};
        for ch = 1:length(channels)
            movefile(fullfile(dataDir, animalID, unit, channels{ch}), ...
                fullfile(dataDir, animalID, unit, 'Ripple', channels{ch}));
        end
    end
end

disp('...done');
