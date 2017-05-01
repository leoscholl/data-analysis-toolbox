function ConvertRippleSpikes(dataDir, animalID, whichUnits, whichFiles, ...
    saveWaveforms)

if nargin < 4
    whichFiles = [];
end
if nargin < 5 || isempty(saveWaveforms)
    saveWaveforms = true;
end
if ~isnumeric(whichUnits)
    error('WhichUnits accepts only unit numbers');
end
if ~isnumeric(whichFiles)
    error('WhichFiles accepts only file numbers');
end

%% Neuroshare Exists
% Check to make sure neuroshare functions are in the MATLAB path
if ~exist('ns_CloseFile.m', 'file')
    disp('WARNING => the neuroshare functions were not found in your MATLAB path.');
    disp('looking in directory ../');
    path(path, '../');
    
    if exist('ns_CloseFile.m', 'file')
        disp('This script found the neuroshare functions in ../');
    else
        disp('In a standard Trellis installation these functions are located in:');
        disp('   <trellis_install_dir>/Tools/matlab/neuroshare>');
    end
    
    % add the path as it is in SVN
    path(path, '..');
    
    if ~exist('ns_CloseFile.m', 'file')
        return;
    end
    
end

disp('Loading ripple spikes...');

%% ns_CloseFile
% when finished using neuroshare functions or to open another data set
% first run ns_CloseFile(hFile). also it is good practice to clear the
% hFile variable from the workspace.
if exist('hFile', 'var')
    ns_CloseFile(hFile); %#ok<*NODEF>
end

for unitNo = whichUnits
    
    unit = ['Unit', deblank(num2str(unitNo))];
    dataPath = fullfile(dataDir, animalID, unit, filesep);
    disp(dataPath);
    
    files = FindFiles(dataDir, animalID, unit, '*].nev', whichFiles); % Choosing all files

    if isempty(files)
        disp('No files found...');
        continue;
    end
    
    for fi = 1:length(files(:,1))
        
        clear nsEntityInfo SpikeTimesAll WaveformsAll
        
        [~, fileName, ~] = fileparts(files(fi,:));
        disp(fileName);

        % get file handle (hFile)
        [ns_RESULT, hFile] = ns_OpenFile([dataPath,fileName,'.nev'],'single');

        if ~strcmp(ns_RESULT, 'ns_OK')
            fprintf(2, 'Failed to open NEV data\n');
            continue;
        end
        
        % open a matlab file to export into
        mFile = matfile([dataPath,fileName,'-export.mat'],'Writable', true);
            
        % get file info structure. This is necessary particularly for getting the
        % EntityCount or the number of Entities in the data set. After getting the
        % number of Entities, we get all of the EntityInfo Structures for each
        % Entity. The EntityInfo Structures contains the EntityType, EntityLabel,
        % and the ItemCount. The ItemCount is the number of occurances or samples
        % of each Entity.
        [ns_RESULT, nsFileInfo] = ns_GetFileInfo(hFile);
        if ~strcmp(ns_RESULT, 'ns_OK')
            fprintf(2, '%s error\n', ns_RESULT);
            continue;
        end
        if nsFileInfo.EntityCount < 1
            fprintf(2, 'File error, possibly corrupt. No units found.');
            continue;
        end
        % get entity info structure. In order to access the EntityInfo
        % information quickly is is written into a structure. To create the
        % structure it must be preallocated first:
        nsEntityInfo(nsFileInfo.EntityCount,1).EntityLabel = '';
        nsEntityInfo(nsFileInfo.EntityCount,1).EntityType = 0;
        nsEntityInfo(nsFileInfo.EntityCount,1).ItemCount = 0;
        % the structure is then filled using ns_GetEntityInfo
        for i = 1:nsFileInfo.EntityCount
            [~, nsEntityInfo(i,1)] = ns_GetEntityInfo(hFile, i);
        end
        
        % get Event/Analog/Segment EntityIDs
        SegmentEntityID = find([nsEntityInfo.EntityType]==3);
        SMA1 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 1')));
        SMA2 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 2')));
        SMA3 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 3')));
        SMA4 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 4')));
        parallel = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, ...
            'Parallel Input')));
        
        SegmentLabel = {nsEntityInfo(SegmentEntityID).EntityLabel};
        SegmentItemCounts = [nsEntityInfo(SegmentEntityID).ItemCount];

        % Extract Spike Times from Ripple Neuroshare Data Files
        disp([num2str(length(SegmentEntityID)), ' electrodes with ', ...
            mat2str(SegmentItemCounts), ' events']);
        
        number = nan(length(SegmentEntityID),1);
        name = cell(length(SegmentEntityID),1);
        for i = 1:length(SegmentEntityID)
            
            % Load electrode names
            label = SegmentLabel{i};
            elecNo = str2num(char(regexp(label, '\d{2}', 'match')));
  
            number(i) = elecNo;
            name{i} = ['elec',num2str(elecNo)];    
        end
        
        electrodes = table(number, name);
        nElectrodes = size(electrodes,1);
        spikes = cell(nElectrodes, 1);
        waveforms = cell(nElectrodes, 1);
        parfor i = 1:nElectrodes
                        
            % Load spike data
            [ns_RESULT, entityInfo] = ns_GetEntityInfo(hFile, SegmentEntityID(i));
            
            tsData = struct('ts', 0.0, 'unit', -1);
            timestamps = repmat(tsData, entityInfo.ItemCount, 1);
            count = 0;
            
            % Iterate through all items and fill wanted timestamps
            for iItem=1:entityInfo.ItemCount
                
                if saveWaveforms
                    [ns_RESULT, ts, data, sample_count, unit_id] = ...
                        ns_GetSegmentData(hFile, SegmentEntityID(i), iItem);
                else
                    [ns_RESULT, ts, sample_count, unit_id] = ...
                        ns_GetSegmentDataFast(hFile, SegmentEntityID(i), iItem);
                    data = [];
                end

                count = count+1;
                timestamps(count).ts = (ts);
                timestamps(count).unit = (unit_id);
                timestamps(count).data = data;
                 
            end
            
            timestamps = timestamps([timestamps(:).unit]~=-1);
            timestamps = timestamps([timestamps(:).ts]~=0);
            
            spikes{i} = [[timestamps.ts]', double([timestamps.unit])'];
            waveforms{i} = [double([timestamps.unit])', double([timestamps.data])'];

        end
        
        if ~saveWaveforms
            waveforms = [];
        end
        
        %% Collect stim times and parallel port information
        stimTimesParallel = [];
        stimTimesPhotodiode = [];
        startTime = [];
        endTime = [];
        parallelInput = [];
    
        % stim times from parallel port (SMA 1)
        if ~isempty(SMA1)
            eventItemCounts = nsEntityInfo(SMA1).ItemCount;
            for i = 1:eventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA1, i);
            end
            stimTimesParallel = EventTimes(1:eventItemCounts)';
        end
    
        % photodiode (SMA 2)
        if ~isempty(SMA2)
            eventItemCounts = nsEntityInfo(SMA2).ItemCount;
            for i = 1:eventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA2, i);
            end
            stimTimesPhotodiode = EventTimes(1:eventItemCounts)';
        end
        
        % start (SMA 3)
        if ~isempty(SMA3)
            eventItemCounts = nsEntityInfo(SMA3).ItemCount;
            for i = 1:eventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA3, i);
            end
            startTime = EventTimes(1);
        end
        
        % stop (SMA 4)
        if ~isempty(SMA4)
            eventItemCounts = nsEntityInfo(SMA4).ItemCount;
            for i = 1:eventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA4, i);
            end
            endTime = EventTimes(1);
        end
        
        % parallel input (Parallel In)
        if ~isempty(parallel)
            eventItemCounts = nsEntityInfo(parallel).ItemCount;
            for i = 1:eventItemCounts
                [~, EventTimes(i), Events(i), EventSizes(i)] = ...
                    ns_GetEventData(hFile, parallel, i);
            end
            parallelInput = [EventTimes(1:eventItemCounts)' ...
                Events(1:eventItemCounts)'];
        end
        
        Ripple = [];
        Ripple.spikeTimes = spikes;
        Ripple.waveforms = waveforms;
        Ripple.electrodes = electrodes;
        Ripple.stimTimesParallel = stimTimesParallel;
        Ripple.stimTimesPhotodiode = stimTimesPhotodiode;
        Ripple.startTime = startTime;
        Ripple.endTime = endTime;
        Ripple.parallelInput = parallelInput;
        
        % save to mFile
        mFile.Ripple = Ripple;
        
        ns_CloseFile(hFile);
        
        disp('done.')
    end
    
end

disp('...done.');
