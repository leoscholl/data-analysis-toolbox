function makeFilesForSorting (dataDir, destDir, animalID, whichUnits, fileType)

if nargin < 4
    fileType='bin';
end
if nargin < 3
    whichUnits = [];
end

% parameters
MAX_INDEX_READ = 10000000; % 10,000,000

units = findUnits(dataDir, animalID, whichUnits);

if isempty(units)
    return;
end

if length(units) > 1 && isempty(gcp('nocreate'))
    parpool; % open a new parallel pool
end

for un = 1:length(units)
    
    unit = units{un};
    unitNo = sscanf(unit, 'Unit%d');
    dataPath = fullfile(dataDir,animalID,unit,filesep);
    destPath = fullfile(destDir,animalID,filesep);
    disp(dataPath);
    
    electrodeid = [];
    Files = [];
    
   
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
            % saving to binary file
            if exist(destPath,'dir') && ...
                    exist([destPath,filesep,animalID,unit,'.bin'],'file')
                % file already exists, overwrite it.
                delete([destPath,filesep,animalID,unit,'.bin']);
            end
        case 'spikes'
            spikes = cell(100,1);
            index = cell(100,1);
            electrodeid = [];
            if exist(destPath,'dir') && ...
                    exist(fullfile(destPath,[animalID,unit,'.mat']),'file')
                %overwrite
                delete(fullfile(destPath,[animalID,unit,'.mat']));
            end
    end
    
    % Find all files for this unit
    switch fileType
        case {'bin', 'mat', 'osort'}
            [~, ~, Files] = findFiles(dataDir, animalID, unitNo, '*.ns5');
        case 'spikes'
            [~, ~, Files] = findFiles(dataDir, animalID, unitNo, '*.mat');
        otherwise
            Files = [];
    end
    if isempty(Files)
        warning('No %s files found for %s', fileType, unit);
        continue;
    end


    nextEnd = 0;
    endTimes = [];
    sampleRate = 30000; % just in case
    
    for fi = 1:size(Files,1)
        
        switch fileType
            case {'bin', 'mat', 'osort'}
                
                fileName = Files.fileName{fi};
                filePath = fullfile(dataPath, [fileName, '.ns5']);
                [ns_RESULT, hFile] = ns_OpenFile(filePath, 'single');
                if ~strcmp(ns_RESULT, 'ns_OK')
                    fprintf(2, 'Failed to open ns5 file for %s\n', FileName);
                    continue;
                end

                % Get file info structure.
                [ns_RESULT, nsFileInfo] = ns_GetFileInfo(hFile);

                % Get entity info structure.
                nsEntityInfo = [];
                nsEntityInfo(nsFileInfo.EntityCount,1).EntityLabel = '';
                nsEntityInfo(nsFileInfo.EntityCount,1).EntityType = 0;
                nsEntityInfo(nsFileInfo.EntityCount,1).ItemCount = 0;
                for i = 1:nsFileInfo.EntityCount
                    [~, nsEntityInfo(i,1)] = ns_GetEntityInfo(hFile, i);
                end

                % Find the Raw channels
                RawEntityID = ...
                    find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, '30 kS/s')));
                if isempty(RawEntityID)
                    RawEntityID = ...
                        find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'raw')));
                end
                rawItemCounts = [nsEntityInfo(RawEntityID).ItemCount];

                % Check item counts
                if max(rawItemCounts) ~= rawItemCounts(1) || min(rawItemCounts) ~= rawItemCounts(1)
                    fprintf(2, 'Error: Different number of samples in each electrode\n');
                end

                % Collect the raw data for all channels simultaneously
                t = 1;
                while t < rawItemCounts(1)

                    IndexCount = min(t+MAX_INDEX_READ/length(RawEntityID), max(rawItemCounts));

                    [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, RawEntityID(1));
                    sampleRate = analogInfo.SampleRate; % Recording duration in 's'

                    % Load analog data
                    [ns_RESULT, data] = ...
                        ns_GetAnalogDataBlock(hFile, RawEntityID, t, IndexCount);
                    if ~strcmp(ns_RESULT, 'ns_OK')
                        fprintf(2, '%s error\n', ns_RESULT);
                        break;
                    end
                    data = data';

                    switch fileType
                        case 'osort'
                            % save bin file for osort
                            if ~exist([destPath,'osort'],'dir')
                                mkdir([destPath,'osort']);
                            end
                            for ch=1:size(data,1)
                                filename = [destPath,'osort',filesep,animalID,unit,'-',num2str(ch),'.bin'];
                                disp(filename);
                                writeLeadpointBinFormat(filename,data(ch,:));
                                % dlmwrite([DataPath,'raw',filesep,'timestampsInclude.txt'],[]);
                                % doesn't seem to work
                            end
                        case 'bin'
                            % Trying filtered data
                            [b,a] = butter(4, [200, 3000]/(sampleRate/2), 'bandpass');
                            for ch = 1:size(data,1)
                                data(ch,:) = filtfilt(b,a,data(ch,:));
                            end
                            %                     [b,a] = butter(4,(200/(SampleRate/2)),'high');
                            %                     [blow,alow] = butter(4,(3000/(SampleRate/2)),'low');
                            %
                            %                     for ch = 1:size(Data,1)
                            %                         Data(ch,:) = filtfilt(b,a,Data(ch,:));
                            %                         Data(ch,:) = filtfilt(blow,alow,Data(ch,:));
                            %                     end

                            % saving raw data to binary file
                            if ~exist(destPath,'dir')
                                mkdir(destPath);
                            end
                            fid = fopen([destPath,animalID,unit,'.bin'],'a');
                            fwrite(fid,data,'int16');
                            fclose(fid);
                    end

                    t = t + IndexCount;

                end
                ns_CloseFile(hFile);

                endTime = rawItemCounts(1)/sampleRate;        
                nextEnd = nextEnd + endTime;
                endTimes(fi,:) = [endTime(1),rawItemCounts(1),nextEnd];
            
                
            case 'spikes'
                
                % save all the unsorted spikes into a file for waveclus
                fileName = Files.fileName{fi};
                fileNo = Files.fileNo(fi);
                disp(fileName);

                % if the file has been exported, then use that data
                dataset = loadExperiment(dataDir, animalID, fileNo, 'Ripple');
                if ~isempty(dataset)
                    nChannels = length(dataset.spike);
                    for i = 1:nChannels
                        spikes{i} = [spikes{i};
                            dataset.spike(i).data'];
                        index{i} = [index{i};
                            1000*dataset.spike(i).time' + nextEnd];
                        electrodeid(i) = dataset.spike(i).electrodeid;
                    end
                    spikeCount = length(dataset.spike(1).time);
                    endTime = 1000*dataset.spike(1).time(end)+10000; % add some artificial separation
                    nextEnd = nextEnd + endTime;
                    endTimes(fi,:) = [endTime(1),spikeCount,nextEnd];
                else
                    spikeCount = 0;
                    endTime = 10000; % add some artificial separation
                    nextEnd = nextEnd + endTime;
                    endTimes(fi,:) = [endTime(1),spikeCount,nextEnd];

                    warning(['empty dataset for ' fileName]);
                end
        end
        
    end
    %     save([DataPath,AnimalID,ExpName,Unit,'-all.mat'],'StimTimesAll','EndTimes','Files');
    Files.duration = endTimes(:,1);
    Files.samples = endTimes(:,2);
    Files.time = [endTimes(:,3) - endTimes(:,1), endTimes(:,3)];
    if ~exist(destPath, 'dir')
        mkdir(destPath);
    end
    if strcmp(fileType, 'spikes')
        spikes = spikes(~cellfun(@isempty,spikes));
        index = index(~cellfun(@isempty,index));
        parsave2([destPath,animalID,unit],Files, spikes, index, electrodeid);
    else
        parsave1([destPath,animalID,unit,'.mat'],Files);
    end
    disp('...done')
end
end

function parsave1(filename, Files)
save(filename, 'Files');
end

function parsave2(filename, Files, waveforms, indices, electrodeid)
for ch = 1:length(electrodeid)
    spikes = waveforms{ch};
    index = indices{ch};
    sr = 30000;
    save([filename, '-', num2str(electrodeid(ch)), 'ch.mat'], ...
        'spikes', 'index', 'sr');
end
save([filename, '.mat'], 'Files');
end