function mergeRawData(destination, varargin)

MAX_INDEX_READ = 10000000; % 10,000,000

endTimes = [];
nextEnd = 0;
spikes = {};
index = {};

[destPath, destination] = fileparts(destination);
destination = fullfile(destPath, destination); % remove ext
if ~exist(destPath,'dir')
    mkdir(destPath);
end
fid = fopen([destination, '.bin'],'w');
fclose(fid);
import NeuroAnalysis.Ripple.*;
for f = 1:length(varargin)
    
    [filePath, fileName, ext] = fileparts(varargin{f});
    file = fullfile(filePath, [fileName, '.ns5']);
    [ns_RESULT, hFile] = ns_OpenFile(file, 'single');
    if ~strcmp(ns_RESULT, 'ns_OK')
        fprintf(2, 'Failed to open ns5 file for %s\n', FileName);
        continue;
    end
    
    % Get file info structure.
    [ns_RESULT, nsFileInfo] = ns_GetFileInfo(hFile);
    
    % Populate entity info structure.
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
        
        IndexCount = min(t+round(MAX_INDEX_READ/length(RawEntityID)), min(rawItemCounts));
        
        [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, RawEntityID(1));
        sampleRate = analogInfo.SampleRate; % Recording duration in 's'
        
        % Load analog data
        [ns_RESULT, data] = ...
            ns_GetAnalogDataBlock(hFile, RawEntityID, t, IndexCount, 'unscale');
        if ~strcmp(ns_RESULT, 'ns_OK')
            fprintf(2, '%s error\n', ns_RESULT);
            break;
        end
        fid = fopen([destination, '.bin'],'a');
        fwrite(fid,data','int16');
        fclose(fid);
        
        t = t + IndexCount;
        
    end
    ns_CloseFile(hFile);
    
    endTime = rawItemCounts(1)/sampleRate;
    nextEnd = nextEnd + endTime;
    endTimes(f,:) = [endTime(1),rawItemCounts(1),nextEnd];
    
end

% save all the unsorted spikes into a single file
Files.duration = endTimes(:,1);
Files.samples = endTimes(:,2);
Files.time = [endTimes(:,3) - endTimes(:,1), endTimes(:,3)];
save([destination, '.mat'], 'Files');

end