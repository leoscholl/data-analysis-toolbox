function ConvertRippleSpikes(DataDir, AnimalID, WhichUnits, WhichFiles)

if nargin < 4
    WhichFiles = [];
end
if ~isnumeric(WhichUnits)
    error('WhichUnits accepts only unit numbers');
end
if ~isnumeric(WhichFiles)
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

for UnitNo = WhichUnits
    
    Unit = ['Unit', deblank(num2str(UnitNo))];
    DataPath = fullfile(DataDir, AnimalID, Unit, filesep);
    disp(DataPath);
    
    Files = FindFiles(DataDir, AnimalID, Unit, '*].nev', WhichFiles); % Choosing all files

    if isempty(Files)
        disp('No files found...');
        continue;
    end
    
    for fi = 1:length(Files(:,1))
        
        clear nsEntityInfo SpikeTimesAll WaveformsAll
        
        [~, FileName, ~] = fileparts(Files(fi,:));
        disp(FileName);

        %% get file handle (hFile)
        [ns_RESULT, hFile] = ns_OpenFile([DataPath,FileName,'.nev'],'single');

        if ~strcmp(ns_RESULT, 'ns_OK')
            fprintf(2, 'Failed to open NEV data\n');
            continue;
        end
        
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
        
        %% get Event/Analog/Segment EntityIDs
        EventEntityID = find([nsEntityInfo.EntityType]==1);
        AnalogEntityID = find([nsEntityInfo.EntityType]==2);
        SegmentEntityID = find([nsEntityInfo.EntityType]==3);
        
        SMA1 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 1')));
        SMA2 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 2')));
        SMA3 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 3')));
        SMA4 = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'SMA 4')));
        Parallel = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, ...
            'Parallel Input')));
        
        %% get Event/Analog/Segment EntityLabels
        EventLabel   = {nsEntityInfo(EventEntityID).EntityLabel}; %#ok<*FNDSB>
        AnalogLabel  = {nsEntityInfo(AnalogEntityID).EntityLabel};
        SegmentLabel = {nsEntityInfo(SegmentEntityID).EntityLabel};
        
        %% Organize item counts by entity type
        EventItemCounts   = [nsEntityInfo(EventEntityID).ItemCount];
        AnalogItemCounts  = [nsEntityInfo(AnalogEntityID).ItemCount];
        SegmentItemCounts = [nsEntityInfo(SegmentEntityID).ItemCount];

        %% Extract Spike Times from Ripple Neuroshare Data Files
        disp([num2str(length(SegmentEntityID)), ' electrodes with ', ...
            mat2str(SegmentItemCounts), ' events']);
        
        SpikeTimesAll_Ripple = [];
        WaveformsAll_Ripple = [];
        ElectrodeNames_Ripple = [];
        lastCount = 0;
        
        for Electrode = 1:length(SegmentEntityID)
            
            %% Load electrode name
            Elec = SegmentLabel{Electrode};
            ElecNo = str2num(char(regexp(Elec, '\d{2}', 'match')));
  
            ElectrodeNames_Ripple{Electrode} = ['elec',num2str(ElecNo)]; %#ok<*AGROW>
            %     SpikeTimes{Electrode,2} = SegmentLabel{Electrode}; %#ok<*AGROW>
            fprintf('%s...', ElectrodeNames_Ripple{Electrode});
            
            %% Load spike data
            [ns_RESULT, entityInfo] = ns_GetEntityInfo(hFile, SegmentEntityID(Electrode));
            
            tsData = struct('ts', 0.0, 'unit', -1);
            timestamps = repmat(tsData, entityInfo.ItemCount, 1);
            count = 0;
            
            % Iterate through all items and fill wanted timestamps
            for iItem=1:entityInfo.ItemCount
                
                [ns_RESULT, ts, data, sample_count, unit_id] = ...
                    ns_GetSegmentData(hFile, SegmentEntityID(Electrode), iItem); %#ok<*ASGLU>

                count = count+1;
                timestamps(count).ts = (ts);
                timestamps(count).unit = (unit_id);
                timestamps(count).data = data;
            end
            timestamps = timestamps([timestamps(:).unit]~=-1);
            timestamps = timestamps([timestamps(:).ts]~=0);
            count = size(timestamps,1);
            
            SpikeTimesAll_Ripple(lastCount+1:lastCount+count,:) = ...
                [repmat(Electrode,count,1), ...
                [timestamps.ts]', ...
                double([timestamps.unit])'];
            WaveformsAll_Ripple(lastCount+1:lastCount+count,:) = ...
                [repmat(Electrode,count,1), ...
                double([timestamps.unit])', ...
                double([timestamps.data])'];
            
%             SpikeTimesAll{Electrode,1} = spikes; %#ok<*AGROW>
%             Units = unique(spikes(:,2));
%             for i = 1:length(Units)
%                 SpikeTempNo = find(spikes(:,2)==Units(i));
%                 WaveformsAll{Electrode, i} = waveforms(SpikeTempNo,:);
%             end
%             
            lastCount = lastCount + count;

        end
        
        %% Collect stim times and parallel port information
        StimTimesParallel = [];
        StimTimesPhotodiode = [];
        StartTime = [];
        EndTime = [];
        ParallelInput = [];
    
        % stim times from parallel port (SMA 1)
        if ~isempty(SMA1)
            EventItemCounts = nsEntityInfo(SMA1).ItemCount;
            for i = 1:EventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA1, i);
            end
            StimTimesParallel = EventTimes(1:EventItemCounts)';
        end
    
        % photodiode (SMA 2)
        if ~isempty(SMA2)
            EventItemCounts = nsEntityInfo(SMA2).ItemCount;
            for i = 1:EventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA2, i);
            end
            StimTimesPhotodiode = EventTimes(1:EventItemCounts)';
        end
        
        % start (SMA 3)
        if ~isempty(SMA3)
            EventItemCounts = nsEntityInfo(SMA3).ItemCount;
            for i = 1:EventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA3, i);
            end
            StartTime = EventTimes(1);
        end
        
        % stop (SMA 4)
        if ~isempty(SMA4)
            EventItemCounts = nsEntityInfo(SMA4).ItemCount;
            for i = 1:EventItemCounts
                [~, EventTimes(i), ~, ~] = ...
                    ns_GetEventData(hFile, SMA4, i);
            end
            EndTime = EventTimes(1);
        end
        
        % parallel input (Parallel In)
        if ~isempty(Parallel)
            EventItemCounts = nsEntityInfo(Parallel).ItemCount;
            for i = 1:EventItemCounts
                [~, EventTimes(i), Events(i), EventSizes(i)] = ...
                    ns_GetEventData(hFile, Parallel, i);
            end
            ParallelInput = [EventTimes(1:EventItemCounts)' ...
                Events(1:EventItemCounts)'];
        end
        
        if ~exist([DataPath,FileName,'-export.mat'],'file')
            save([DataPath,FileName,'-export.mat'],'SpikeTimesAll_Ripple',...
            'WaveformsAll_Ripple','ElectrodeNames_Ripple',...
            'StimTimesParallel','StimTimesPhotodiode', 'StartTime', ...
            'EndTime', 'ParallelInput')
        else
            save([DataPath,FileName,'-export.mat'],'SpikeTimesAll_Ripple',...
                'WaveformsAll_Ripple','ElectrodeNames_Ripple',...
                'StimTimesParallel','StimTimesPhotodiode', 'StartTime', ...
                'EndTime', 'ParallelInput','-append')
        end
        
        ns_CloseFile(hFile);
        
        disp('done.')
    end
    
end

disp('...done.');
