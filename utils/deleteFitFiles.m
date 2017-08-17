function deleteFitFiles(baseDir, animalID, whichUnits, whichFiles, sourceFormat)

if nargin < 5 || isempty(sourceFormat)
    sourceFormat = 'Ripple';
end

% [~, ~, Files] = findFiles(baseDir, animalID, whichUnits, '*', whichFiles);
% for f = 1:size(Files,1)
%     
%     fileName = Files.fileName{f};
%     unit = Files.unit{f};
%     
%     % delete for the unit
%     dataPath = fullfile(baseDir, animalID, unit);
%     delete(fullfile(dataPath, [fileName, '*.png']), ...
%         fullfile(dataPath, [fileName, '*.fig']));
% end

% delete for all channels
units = findUnits(baseDir, animalID, whichUnits);
for u = 1:length(units)
    unit = units{u};
    unitNo = sscanf(unit, 'Unit%d');
    figuresPath = fullfile(baseDir, animalID, unit, sourceFormat);
    channels = dir(fullfile(figuresPath,'Ch*'));
    if isempty(channels)
        continue;
    end
    channels = {channels(vertcat(channels.isdir)).name};
    for ch = 1:length(channels)
        channelName = channels{ch};
        [~, ~, Files] = findFiles(baseDir, animalID, unitNo, ...
            fullfile(sourceFormat, channelName, '*'), whichFiles);
        for f = 1:size(Files,1)
            fileName = Files.fileName{f};
            unit = Files.unit{f};
            figuresPath = fullfile(baseDir, animalID, unit, ...
                sourceFormat, channelName);
            delete(fullfile(figuresPath, [fileName, '*.png']), ...
                fullfile(figuresPath, [fileName, '*.fig']));
        end
    end
end