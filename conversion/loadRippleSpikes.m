function Electrodes = loadRippleSpikes(dataPath, fileName, Electrodes, ...
    whichElectrodes)

narginchk(2,4);

if nargin < 3
    Electrodes = table(cell(0),cell(0),cell(0),[]);
    Electrodes.Properties.VariableNames = {'spikes','waveforms','name','number'};
end
if nargin < 4
    whichElectrodes = [];
end

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
    error(2, '%s error\n', ns_RESULT);
end
if nsFileInfo.EntityCount < 1
    error(2, 'File error, possibly corrupt. No units found.');
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
SegmentLabel = {nsEntityInfo(SegmentEntityID).EntityLabel};
SegmentItemCounts = [nsEntityInfo(SegmentEntityID).ItemCount];

% load electrode names
number = nan(length(SegmentEntityID),1);
name = cell(length(SegmentEntityID),1);
for i = 1:length(SegmentEntityID)
    label = SegmentLabel{i};
    elecNo = str2num(char(regexp(label, '\d{1,2}', 'match')));
    number(i) = elecNo(end);
    name{i} = ['elec',num2str(elecNo(end))];
end

% choose the correct electrodes
if isempty(whichElectrodes)
    whichElectrodes = logical(ones(length(SegmentEntityID),1));
else
    whichElectrodes = ismember(number, whichElectrodes);
    number = number(whichElectrodes);
end
SegmentEntityID = SegmentEntityID(whichElectrodes);
SegmentItemCounts = SegmentItemCounts(whichElectrodes);
name = name(whichElectrodes);
disp([num2str(length(SegmentEntityID)), ' electrodes with ', ...
    mat2str(SegmentItemCounts), ' events']);
nElectrodes = length(number);

% fill the spikes array
spikesTmp = cell(length(number),1);
parfor i = 1:length(number)
    
    thisID = SegmentEntityID(i);
    
    % Load spike data
    [ns_RESULT, entityInfo] = ns_GetEntityInfo(hFile, thisID);
    
    tsData = struct('ts', 0.0, 'unit', -1);
    timestamps = repmat(tsData, entityInfo.ItemCount, 1);
    count = 0;
    
    % Iterate through all items and fill wanted timestamps
    for iItem=1:entityInfo.ItemCount
        
        [ns_RESULT, ts, unit_id] = ...
            ns_GetSegmentDataFast(hFile, thisID, iItem);
        
        count = count+1;
        timestamps(count).ts = (ts);
        timestamps(count).unit = (unit_id);        
    end
    
    timestamps = timestamps([timestamps(:).unit]~=-1);
    timestamps = timestamps([timestamps(:).ts]~=0);
    
    spikesTmp{i} = [[timestamps.ts]', double([timestamps.unit])'];
    
end

% fill the Electrode table
for i = 1:length(number)
    waveforms = {[]};
    try
        waveforms = Electrodes.waveforms(number(i));
    catch
    end
    Electrodes(number(i),:) = {spikesTmp(i), waveforms, name(i), number(i)};
end

% close the file handle
ns_CloseFile(hFile);
