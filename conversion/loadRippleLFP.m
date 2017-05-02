function LFP = loadRippleLFP(dataPath, fileName)

narginchk(2,2);

% Check that neuroshare exists
assertNeuroshare();

% get file handle (hFile)
[ns_RESULT, hFile] = ...
    ns_OpenFile(fullfile(dataPath,[fileName,'.ns2']),'single');

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


% get Analog EntityID
LFPEntityID = ...
    find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, '1 kS/s')));
if isempty(LFPEntityID)
    LFPEntityID = ...
        find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, 'lfp')));
end

label = {nsEntityInfo(LFPEntityID).EntityLabel};
itemCounts = [nsEntityInfo(LFPEntityID).ItemCount];
disp([num2str(length(LFPEntityID)), ' electrodes with ', ...
    num2str(itemCounts(1)/1000), ' seconds of LFP data']);
        
% Check item counts
if any(itemCounts ~= mean(itemCounts))
    fprintf(2, 'Error: Different number of samples in each electrode\n');
end

% Collect the raw data for all channels simultaneously
[ns_RESULT, dataTmp] = ...
    ns_GetAnalogDataBlock(hFile, LFPEntityID, 1, max(itemCounts));
if ~strcmp(ns_RESULT, 'ns_OK')
    error(2, '%s error\n', ns_RESULT);
end

% Put data into a cell array
nElectrodes = length(LFPEntityID);
data = cell(nElectrodes,1);
for i=1:nElectrodes
    data{i} = dataTmp(:,i);
end

% load electrode names
number = nan(length(LFPEntityID),1);
name = cell(length(LFPEntityID),1);
for i = 1:length(LFPEntityID)
    name{i} = label{i};
    number(i) = i;
end

[ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, LFPEntityID(1));
if ~strcmp(ns_RESULT, 'ns_OK')
    error(2, '%s error\n', ns_RESULT);
end

LFP = [];
LFP.sampleRate = analogInfo.SampleRate;
LFP.endTime = itemCounts/LFP.sampleRate; % Recording duration in 's'
LFP.Electrodes = table(data, name, number);

ns_CloseFile(hFile);
end
