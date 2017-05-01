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
    
    Files = FindFiles(DataDir, AnimalID, Unit, '*].ns2', WhichFiles); % Choosing all files

    if isempty(Files)
        disp('No files found...');
        continue;
    end
    
    for fi = 1:length(Files(:,1))
        
        clear nsEntityInfo SpikeTimesAll WaveformsAll
        
        [~, FileName, ~] = fileparts(Files(fi,:));
        disp(FileName);

        %% get file handle (hFile)
        [ns_RESULT, hFile] = ns_OpenFile([DataPath,FileName,'.ns2'],'single');

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
        LFPEntityID = ...
            find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, '1 kS/s')));
        
        if isempty(LFPEntityID)
            LFPEntityID = ...
                find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'lfp')));
        end

        
        %% get Event/Analog/Segment EntityLabels
        EventLabel   = {nsEntityInfo(EventEntityID).EntityLabel}; %#ok<*FNDSB>
        AnalogLabel  = {nsEntityInfo(AnalogEntityID).EntityLabel};
        SegmentLabel = {nsEntityInfo(SegmentEntityID).EntityLabel};
        LFPLabel = {nsEntityInfo(LFPEntityID).EntityLabel};
        
        %% Organize item counts by entity type
        EventItemCounts   = [nsEntityInfo(EventEntityID).ItemCount];
        AnalogItemCounts  = [nsEntityInfo(AnalogEntityID).ItemCount];
        SegmentItemCounts = [nsEntityInfo(SegmentEntityID).ItemCount];
        LFPItemCounts = [nsEntityInfo(LFPEntityID).ItemCount];

        %% Extract Spike Times from Ripple Neuroshare Data Files
        disp([num2str(length(LFPEntityID)), ' electrodes with ', ...
            num2str(LFPItemCounts(1)/1000), ' seconds of LFP data']);
        
        LFPDataAll = [];
        LFPElectrodeNames = [];
        
        for Electrode = 1:length(LFPEntityID)
            
            %% Load electrode name
            Elec = LFPLabel{Electrode};
            % ElecNo = str2num(char(regexp(Elec, '\d*$', 'match')));
  
            LFPElectrodeNames{Electrode} = Elec; %#ok<*AGROW>
            fprintf('%s...', Elec);
            
            %% Load LFP data
            [ns_RESULT, countList, data] = ...
                ns_GetAnalogData(hFile, LFPEntityID(Electrode), 1, ...
                LFPItemCounts(Electrode));
            LFPDataAll(Electrode,:) = data; %#ok<*AGROW>
            
        end
        
        [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, LFPEntityID(Electrode));
        if ~strcmp(ns_RESULT, 'ns_OK')
            fprintf(2, '%s error\n', ns_RESULT);
            return
        end
        
        LFPSampleRate = analogInfo.SampleRate; 
        LFPEndTime = LFPItemCounts/LFPSampleRate; % Recording duration in 's'
        
        if ~exist([DataPath,FileName,'-export.mat'],'file')
            save([DataPath,FileName,'-export.mat'],'LFPDataAll','LFPEndTime',...
                'LFPSampleRate','LFPElectrodeNames');
        else
             save([DataPath,FileName,'-export.mat'],'LFPDataAll','LFPEndTime',...
                'LFPSampleRate','LFPElectrodeNames','-append');
        end
        
        ns_CloseFile(hFile);
        
        disp('done.')
    end
    
end

disp('...done.');
