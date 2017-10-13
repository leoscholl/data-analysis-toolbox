function makeFilesForSorting (dataDir, destDir, animalID, whichFiles)
% Combines individual datasets into one big spikes file for each unit

if nargin < 4
    whichFiles = [];
end

% Gather all applicable files
[~, ~, Files] = findFiles(dataDir, animalID, [], '*].mat', whichFiles);

Files.spike = repmat({[]}, size(Files,1),1);

% Load spike data
for f = 1:size(Files,1)
    
    fileNo = Files.fileNo(f);
    dataset = loadExperiment(dataDir, animalID, fileNo, 'Ripple');
    
    if isempty(dataset) || ~isfield(dataset, 'ex') || ~isfield(dataset, 'spike')
        continue;
    end
    
    Files.unit(f) = {dataset.ex.unit};
    Files.spike(f) = {dataset.spike};
    
end

Files = Files(~cellfun(@isempty, Files.unit),:);
units = unique(Files.unit);

% Iterate through units to make new spike files
for u = 1:length(units)
    
    disp(units{u});
    destPath = fullfile(destDir,animalID,filesep);
    
    UnitFiles = Files(cellfun(@(x)strcmp(x, units{u}), Files.unit),:);
    
    endTimes = [];
    nextEnd = 0;
    spikes = {};
    index = {};
    electrodeid = [];
    for f = 1:size(UnitFiles,1)
        nChannels = length(UnitFiles.spike{f});
        for i = 1:nChannels
            electrodeid(i) = UnitFiles.spike{f}(i).electrodeid;
            if length(spikes) < electrodeid(i)
                spikes{electrodeid(i)} = [];
                index{electrodeid(i)} = [];
            end
            spikes{electrodeid(i)} = [spikes{electrodeid(i)};
                UnitFiles.spike{f}(i).data'];
            index{electrodeid(i)} = [index{electrodeid(i)};
                1000*UnitFiles.spike{f}(i).time' + nextEnd];
        end
        
        spikeCount = length(UnitFiles.spike{f}(1).time);
        endTime = 1000*UnitFiles.spike{f}(1).time(end)+10000; % add some artificial separation
        nextEnd = nextEnd + endTime;
        endTimes(f,:) = [endTime(1),spikeCount,nextEnd];
        UnitFiles.spike{f} = [];
    end
        
    % save all the unsorted spikes into a single file
    UnitFiles.duration = endTimes(:,1);
    UnitFiles.samples = endTimes(:,2);
    UnitFiles.time = [endTimes(:,3) - endTimes(:,1), endTimes(:,3)];
    if ~exist(destPath, 'dir')
        mkdir(destPath);
    end
    
    electrodes = find(~cellfun(@isempty,spikes));
    spikes = spikes(~cellfun(@isempty,spikes));
    index = index(~cellfun(@isempty,index));
    parsave([destPath,animalID,units{u}],UnitFiles, spikes, index, electrodes);
end
end

function parsave(filename, Files, waveforms, indices, electrodeid)
for ch = 1:length(electrodeid)
    spikes = waveforms{ch};
    index = indices{ch};
    sr = 30000;
    save([filename, '-', num2str(electrodeid(ch)), 'ch.mat'], ...
        'spikes', 'index', 'sr');
end
save([filename, '.mat'], 'Files');
end