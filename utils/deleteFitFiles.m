function deleteFitFiles(dir, animalID, whichUnits)

disp(['deleting figures for ', animalID, ' units ', mat2str(whichUnits)]);

units = FindUnits(dir, animalID, whichUnits);

if isempty(units)
    return
end

for unt = 1:length(units(:,1))
    
    % delete for the unit
    dataPath = fullfile(dir, animalID, deblank(units(unt,:)));
    delete(fullfile(dataPath, '*.png'), fullfile(dataPath, '*.fig'));

    % delete for all channels
    dataPath = fullfile(dir,animalID,deblank(units(unt,:)));
    channels = dir(fullfile(dataPath,'Ch*'));
    if isempty(channels)
        fprintf('nothing to delete for unit %d...\n', unt);
        continue;
    end
    channels = vertcat(channels(vertcat(channels.isdir)).name);
    for ch = 1:length(channels(:,1))
        rmdir(fullfile(dataPath,channels(ch,:)),'s');
    end
end

disp(['...done deleting for ', animalID]);