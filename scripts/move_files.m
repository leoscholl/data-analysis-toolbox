disp('copying files...')

DataDir = 'I:\Data\';
DestDir = 'I:\Results\';

AnimalID = 'R1701';
WhichUnits = [];

Units = FindUnits(DataDir, AnimalID, WhichUnits);

for i=1:size(Units,1)
    Unit = Units(i,:);

    DataPath = fullfile(DataDir, AnimalID, Unit);
    DestPath = fullfile(DestDir, AnimalID, Unit);

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

    %% copy sorted files
    % DataPath = fullfile(DataDir, AnimalID, Unit, 'results\5');
    % DestPath = fullfile(DestDir, AnimalID, Unit, 'results\5');
    % if ~exist(DestPath,'dir')
    %     mkdir(DestPath);
    % end
    % CopyFiles('*.mat', DataPath, DestPath);
    
    %% Delete files
    delete(fullfile(DataPath,'*]-spikes.mat'));
    delete(fullfile(DataPath,'*]-params.mat'));
    delete(fullfile(DataPath,'*]-lfp.mat'));
end

