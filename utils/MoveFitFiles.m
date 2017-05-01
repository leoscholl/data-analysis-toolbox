function MoveFitFiles(DataDir, DestDir, AnimalID, WhichUnits)

disp(['copying files for ', AnimalID, ' units ', mat2str(WhichUnits)]);

Units = FindUnits(DataDir, AnimalID, WhichUnits);

if ~exist(DestDir, 'dir')
    mkdir(DestDir)
end

for unt = 1:length(Units(:,1))
    
    DataPath1 = ([DataDir,AnimalID,'\',deblank(Units(unt,:)),'\']);
    Channels1 = ls(DataPath1);
    if isempty(Channels1)
        % nothing to copy here
        continue;
    end
    Channels1 = Channels1(3:end,:);
    
    chann = zeros(length(Channels1(:,1)),1);
    for chan = 1:length(Channels1(:,1))
        if strcmp(Channels1(chan,1:2),'Ch')
            chann(chan) = 1;
        end
    end
    clear Channels
    Channels = Channels1(chann==1,:);
    
    % copy for all channels
    for ch = 1:length(Channels(:,1))
        Path = fullfile(AnimalID,deblank(Units(unt,:)),deblank(Channels(ch,:)));
        DataPath = fullfile(DataDir, Path);
        DestPath = fullfile(DestDir, Path);
        
        % only copy if there are less files than there should be
        NumDataFiles = length(dir(DataPath));
        NumCopyFiles = length(dir(DestPath));
        if NumCopyFiles < NumDataFiles
            copyfile(DataPath,DestPath);
            disp(DataPath);
        end
    end

end

disp(['...done copying for ', AnimalID]);