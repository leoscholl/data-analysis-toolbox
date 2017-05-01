function DeleteFitFiles(Dir, AnimalID, WhichUnits)

disp(['deleting figures for ', AnimalID, ' units ', mat2str(WhichUnits)]);

Units = FindUnits(Dir, AnimalID, WhichUnits);

if isempty(Units)
    return
end

for unt = 1:length(Units(:,1))
    
    % delete for the unit
    DataPath = fullfile(Dir, AnimalID, deblank(Units(unt,:)));
    delete(fullfile(DataPath, '*.png'), fullfile(DataPath, '*.fig'));

    % delete for all channels
    DataPath = fullfile(Dir,AnimalID,deblank(Units(unt,:)));
    Channels = dir(fullfile(DataPath,'Ch*'));
    if isempty(Channels)
        fprintf('nothing to delete for unit %d...\n', unt);
        continue;
    end
    Channels = vertcat(Channels(vertcat(Channels.isdir)).name);
    for ch = 1:length(Channels(:,1))
        rmdir(fullfile(DataPath,Channels(ch,:)),'s');
    end
end

disp(['...done deleting for ', AnimalID]);