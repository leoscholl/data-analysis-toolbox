function MakeFilesForSorting (DataDir, AnimalID, WhichUnits, FileType)

if nargin < 4
    FileType='bin';
end
if nargin < 3
    WhichUnits = [];
end

% parameters
max_index_read = 10000000; % 10,000,000

% Close hfile if it already exists
if exist('hFile', 'var')
    ns_CloseFile(hFile); %#ok<*NODEF>
end

Units = FindUnits(DataDir, AnimalID, WhichUnits);

if isempty(Units)
    return;
end

for un = 1:length(Units(:,1))
       
    Unit = deblank(Units(un,:));
    
    DataPath = [DataDir,AnimalID,filesep,Unit,filesep];
    disp(DataPath);
    %Files = ls([DataPath,'*',ExpName,'*','.ns5']);
    Files = dir([DataPath,'*.ns5']); % Choosing all files
    Files = char(Files.name);
    if isempty(Files)
        warning(['No ns5 files found for ', Unit]);
        continue;
    end
    
    % Check for existing files
    switch FileType 
        case 'osort'
            if exist([DataPath,'osort'],'dir') && ...
                    exist([DataPath,'osort',filesep,AnimalID,Unit,'-1.bin'], 'file')
                % file already exists, skip.
                disp([DataPath,'osort',filesep,AnimalID,Unit,'-1.bin already exists']);
                continue;
            end
            
            %% TODO:
            % the above only checks for the 1st channel. maybe want to
            % extend to all channels for that unit
            
        case 'mat'
            if exist([DataPath,AnimalID,Unit,'-raw.mat'],'file')
                % file already exists, skip.
                disp([DataPath,AnimalID,Unit,'-raw.mat already exists']);
                continue;
            end
        case 'bin'
            % saving LFP data to binary file
            if exist([DataPath,'raw'],'dir') && ...
                    exist([DataPath,'raw',filesep,AnimalID,Unit,'.bin'],'file')
                % file already exists, skip.
                disp([DataPath,'raw',filesep,AnimalID,Unit,'.bin already exists']);
                continue;
            end
    end

    % Sort files
    FileID = NaN(length(Files(:,1)),1);
    for fi = 1:length(Files(:,1))
        FileName1 = deblank(Files(fi,:));
        FindLeftBracket = findstr(FileName1,'[');
        FindCross = findstr(FileName1,'#');
        
        FileID(fi) = str2num(FileName1(FindCross+1:FindLeftBracket-1));
    end
    [~,IX] = sort(FileID);
    Files = Files(IX,:);
    
%     % Chosing proper files
%     counter2 = 0;
%     clear ktore
%     for fl = 1:length(FilesNo)
%         if ~isempty(find(B == FilesNo(fl))) %#ok<EFIND>
%             counter2 = counter2+1;
%             ktore(counter2) = find(B == FilesNo(fl));
%         end
%     end
%     Files = Files(ktore,:);
    
    % Loading and merging files in proper order
    NextEnd = 0;
    
    for fi = 1:length(Files(:,1))
        
        [~, FileName, ~] = fileparts(Files(fi,:));     
        FilePath = fullfile(DataPath, FileName);
        
        [ns_RESULT, hFile] = ns_OpenFile(FilePath);
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
        RawItemCounts = [nsEntityInfo(RawEntityID).ItemCount];
        
        % Check item counts
        if max(RawItemCounts) ~= RawItemCounts(1) || min(RawItemCounts) ~= RawItemCounts(1)
            fprintf(2, 'Error: Different number of samples in each electrode\n');
        end
        
        % Collect the raw data for all channels simultaneously
        t = 1;
        while t < RawItemCounts(1)
            
            IndexCount = min(t+max_index_read/length(RawEntityID), max(RawItemCounts));
            
            [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, RawEntityID(1));
            SampleRate = analogInfo.SampleRate; % Recording duration in 's'
            
            % Load analog data
            clear Data;
            [ns_RESULT, Data] = ...
                ns_GetAnalogDataBlock(hFile, RawEntityID, t, IndexCount);
            if ~strcmp(ns_RESULT, 'ns_OK')
                fprintf(2, '%s error\n', ns_RESULT);
                break;
            end
            Data = Data';
            
            switch FileType 
                case 'osort'
                    % save bin file for osort
                    if ~exist([DataPath,'osort'],'dir')
                        mkdir([DataPath,'osort']);
                    end
                    for ch=1:size(Data,1)
                        filename = [DataPath,'osort',filesep,AnimalID,Unit,'-',num2str(ch),'.bin'];
                        disp(filename);
                        writeLeadpointBinFormat(filename,Data(ch,:));
                        % dlmwrite([DataPath,'raw',filesep,'timestampsInclude.txt'],[]);
                        % doesn't seem to work
                    end
                case 'bin'
                    % Trying filtered data
                    [b,a] = butter(4,(200/(SampleRate/2)),'high');
                    [blow,alow] = butter(4,(3000/(SampleRate/2)),'low');

                    for ch = 1:size(Data,1)
                        Data(ch,:) = filtfilt(b,a,Data(ch,:));
                        Data(ch,:) = filtfilt(blow,alow,Data(ch,:));
                    end

                    % saving LFP data to binary file
                    if ~exist([DataPath,'raw'],'dir')
                        mkdir([DataPath,'raw']);
                    end
                    fid = fopen([DataPath,'raw',filesep,AnimalID,Unit,'.bin'],'a');
                    fwrite(fid,Data,'int16');
                    fclose(fid);
            end
            
            t = t + IndexCount;
        
        end
        
        
        % Get Stimulus Times;
        EventEntityID = find([nsEntityInfo.EntityType]==1);
        EventItemCounts   = [nsEntityInfo(EventEntityID).ItemCount];

        StimTimes = [];
        
        EventEntityCount  = length(EventEntityID);
        EventTimes        = nan(max(EventItemCounts), EventEntityCount);
        for i = 1:EventEntityCount
            for j = 1:EventItemCounts(i)
                [~, EventTimes(j,i), ~, ~] = ...
                    ns_GetEventData(hFile, EventEntityID(i), j);
            end
        end
        
        if ~isempty(EventTimes)
            StimTimes = EventTimes(1:2:end,1);
        else
            StimTimes = [];
        end
        EndTime = max(RawItemCounts)/SampleRate;

        StimTimesAll{fi} = StimTimes;
        NextEnd = NextEnd + EndTime(1);
        EndTimes(fi,:) = [EndTime(1),RawItemCounts(1),NextEnd];
        
        clear StimTimes EndTime
        
        ns_CloseFile(hFile);

    end
%     save([DataPath,AnimalID,ExpName,Unit,'-all.mat'],'StimTimesAll','EndTimes','Files');
    save([DataPath,AnimalID,Unit,'.mat'],'StimTimesAll','EndTimes','Files');
    disp('...done')
end

clear all;

% fid = fopen([DataPath,FileName,'.bin'],'w');
% %fwrite(fid,LFPdata,'uint16');
% lfp = fread(fid,size(LFPdata), 'int16');
% fclose(fid);

%%
% Create the file
% fid = fopen('magic5.bin', 'w');
% fwrite(fid, magic(5));
% fclose(fid);
% 
% % Read the contents back into an array
% fid = fopen('magic5.bin');
% m5 = fread(fid, [5, 5], '*uint8');
% fclose(fid);


% visdiff()