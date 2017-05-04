function Analog = loadRippleAnalog(dataPath, fileName, dataType)

narginchk(2,3);

if nargin < 3
    dataType = 'lfp';
end

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
analogEntityID = ...
    find(~cellfun('isempty', strfind({nsEntityInfo.EntityLabel}, dataType)));


label = {nsEntityInfo(analogEntityID).EntityLabel};
itemCounts = [nsEntityInfo(analogEntityID).ItemCount];
disp([num2str(length(analogEntityID)), ' electrodes with ', ...
    num2str(itemCounts(1)/1000), ' seconds of analog data']);
        
% Check item counts
if any(itemCounts ~= mean(itemCounts))
    fprintf(2, ['Error: Different number of samples in each channel.'...
        'Truncating.\n']);
end

% Collect the raw data for all channels simultaneously
[ns_RESULT, dataTmp] = ...
    ns_GetAnalogDataBlock(hFile, analogEntityID, 1, min(itemCounts));
if ~strcmp(ns_RESULT, 'ns_OK')
    error(2, '%s error\n', ns_RESULT);
end

% Put data into a cell array
nChannels = length(analogEntityID);
data = cell(nChannels,1);
for i=1:nChannels
    data{i} = dataTmp(:,i);
end

% load electrode names
number = nan(length(analogEntityID),1);
name = cell(length(analogEntityID),1);
for i = 1:length(analogEntityID)
    name{i} = label{i};
    number(i) = i;
end

[ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, analogEntityID(1));
if ~strcmp(ns_RESULT, 'ns_OK')
    error(2, '%s error\n', ns_RESULT);
end

Analog = [];
Analog.sampleRate = analogInfo.SampleRate;
Analog.endTime = itemCounts/Analog.sampleRate; % Recording duration in 's'
Analog.Channels = table(data, name, number);

ns_CloseFile(hFile);
end
