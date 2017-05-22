function Events = loadRippleEvents(dataPath, fileName)

narginchk(2,2);

Events = [];

% Check that neuroshare exists
assertNeuroshare();

% get file handle (hFile)
filePath = fullfile(dataPath,[fileName,'.nev']);
if ~exist(filePath,'file')
    warning(['No NEV file for ', fileName]);
    return
end
[ns_RESULT, hFile] = ...
    ns_OpenFile(filePath,'single');

if ~strcmp(ns_RESULT, 'ns_OK')
    error('Failed to open NEV data\n');
end

% get file info structure. This is necessary particularly for getting the
% EntityCount or the number of Entities in the data set. After getting the
% number of Entities, we get all of the EntityInfo Structures for each
% Entity. The EntityInfo Structures contains the EntityType, EntityLabel,
% and the ItemCount. The ItemCount is the number of occurances or samples
% of each Entity.
[ns_RESULT, nsFileInfo] = ns_GetFileInfo(hFile);
if ~strcmp(ns_RESULT, 'ns_OK')
    error('%s error\n', ns_RESULT);
end
if nsFileInfo.EntityCount < 1
    error('File error, possibly corrupt. No units found.');
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

% get Event EntityIDs
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

% Collect stim times and parallel port information
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

StimTimes = [];
StimTimes.parallel = stimTimesParallel;
StimTimes.photodiode = stimTimesPhotodiode;
Events = [];
Events.StimTimes = StimTimes;
Events.startTime = startTime;
Events.endTime = endTime;
Events.parallelInput = parallelInput;

ns_CloseFile(hFile);

end
