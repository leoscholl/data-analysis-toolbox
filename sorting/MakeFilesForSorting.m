function makeFilesForSorting (dataDir, destDir, animalID, whichUnits, fileType)

if nargin < 4
    fileType='bin';
end
if nargin < 3
    whichUnits = [];
end

units = findUnits(dataDir, animalID, whichUnits);

if isempty(units)
    return;
end

if isempty(gcp('nocreate'))
    parpool; % open a new parallel pool
end

for un = 1:length(units)
       
    unit = units{un};
    unitNo = sscanf(unit, 'Unit%d');
    dataPath = fullfile(dataDir,animalID,unit,filesep);
    destPath = fullfile(destDir,animalID,unit,filesep);
    disp(dataPath);

    [files, ~, Files] = findFiles(dataDir, animalID, unitNo, '*.mat');
    if isempty(Files)
        warning(['No ns5 files found for ', unit]);
        continue;
    end
    
    % Check for existing files
    switch fileType 
        case 'osort'
            if exist([dataPath,'osort'],'dir') && ...
                    exist([dataPath,'osort',filesep,animalID,unit,'-1.bin'], 'file')
                % file already exists, skip.
                disp([dataPath,'osort',filesep,animalID,unit,'-1.bin already exists']);
                continue;
            end
            
            %% TODO:
            % the above only checks for the 1st channel. maybe want to
            % extend to all channels for that unit
            
        case 'mat'
            if exist([dataPath,animalID,unit,'-raw.mat'],'file')
                % file already exists, skip.
                disp([dataPath,animalID,unit,'-raw.mat already exists']);
                continue;
            end
        case 'bin'
            % saving LFP data to binary file
            if exist(destPath,'dir') && ...
                    exist([destPath,filesep,animalID,unit,'.bin'],'file')
                % file already exists, overwrite it.
                delete([destPath,filesep,animalID,unit,'.bin']);
            end
    end
    
    nextEnd = 0;
    endTimes = [];
    
    for fi = 1:size(Files,1)
        
        fileName = Files.fileName{fi};
        filePath = fullfile(dataPath, fileName);
        disp(fileName);
        
        % if the file has been exported, then use that data
        fileVars = who('-file', filePath);
        if ismember('dataset', fileVars)
            file = load(filePath, 'dataset');
            data = file.dataset.raw.data';
            rawItemCounts = size(data,2);
            endTime = file.dataset.raw.time(end);
            sampleRate = file.dataset.raw.fs;
            nextEnd = nextEnd + endTime;
            endTimes(fi,:) = [endTime(1),rawItemCounts(1),nextEnd];
            
            [b,a] = butter(4, [200, 3000]/(sampleRate/2), 'bandpass');
            for ch = 1:size(data,1)
                data(ch,:) = filtfilt(b,a,data(ch,:));
            end
            
            % saving raw data to binary file
            if ~exist(destPath,'dir')
                mkdir(destPath);
            end
            
            fid = fopen([destPath,animalID,unit,'.bin'],'a');
            fwrite(fid,data,'int16');
            fclose(fid);
        else
            error([fileName, ' has not been exported yet']);
        end

    end
    
    Files.duration = endTimes(:,1);
    Files.samples = endTimes(:,2);
    Files.time = [endTimes(:,3) - endTimes(:,1), endTimes(:,3)];
    parsave([destPath,animalID,unit,'.mat'],Files);
    disp('...done')
end
end

function parsave(filename, Files)
save(filename, 'Files');
end