function deleteFitFiles(baseDir, animalID, whichUnits, whichFiles)

[~, ~, Files] = findFiles(baseDir, animalID, whichUnits, '*', whichFiles);
for f = 1:size(Files,1)
    
    fileName = Files.fileName{f};
    unit = Files.unit{f};
    
    % delete for the unit
    dataPath = fullfile(baseDir, animalID, unit);
    delete(fullfile(dataPath, [fileName, '*.png']), ...
        fullfile(dataPath, [fileName, '*.fig']));
end

% delete for all channels
units = findUnits(baseDir, animalID, whichUnits);
for u = 1:length(units)
    unit = units{u};
    dataPath = fullfile(baseDir, animalID, unit);
    channels = [dir(fullfile(dataPath,'Ch*'));
                dir(fullfile(dataPath,'StimTimes*'))];
    if isempty(channels)
        continue;
    end
    channels = {channels(vertcat(channels.isdir)).name};
    for ch = 1:length(channels)
        channelName = channels{ch};
        [~, ~, Files] = findFiles(baseDir, animalID, whichUnits, ...
            fullfile(channelName, '*'), whichFiles);
        for f = 1:size(Files,1)
            fileName = Files.fileName{f};
            unit = Files.unit{f};
            dataPath = fullfile(baseDir, animalID, unit, channelName);
            delete(fullfile(dataPath, [fileName, '*.png']), ...
                fullfile(dataPath, [fileName, '*.fig']));
        end
    end
end

disp(['...done deleting for ', animalID]);