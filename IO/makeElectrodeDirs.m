function pathMap = makeElectrodeDirs(dataset, basePath)
%makeElectrodeDirs Create and return a map of directories for the given
%dataset

dataDir = makeDatasetDir(dataset, basePath);
pathMap = containers.Map('KeyType','double','ValueType','char');
electrodes = union([dataset.spike.electrodeid], dataset.lfp.electrodeid, 'sorted');
for i = 1:length(electrodes)
    elecDir = fullfile(dataDir, sprintf('Ch%02d',electrodes(i)));
    if ~isdir(elecDir)
        mkdir(elecDir)
    end
    pathMap(electrodes(i)) = elecDir;
end
