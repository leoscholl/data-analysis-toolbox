function pathMap = makeElectrodeDirs(dataset, basePath)
%makeElectrodeDirs Create and return a map of directories for the given
%dataset

dataDir = makeDatasetDir(dataset.ex.Subject_ID, dataset.ex.RecordSite, ...
    dataset.ex.RecordSession, basePath);
pathMap = containers.Map('KeyType','double','ValueType','char');
espike = [];
elfp = [];
if isfield(dataset, 'spike')
    espike = [dataset.spike.electrodeid];
end
if isfield(dataset, 'lfp')
    elfp = dataset.lfp.electrodeid;
end
electrodes = union(espike, elfp, 'sorted');
for i = 1:length(electrodes)
    elecDir = fullfile(dataDir, sprintf('Ch%02d',electrodes(i)));
    if ~isdir(elecDir)
        mkdir(elecDir)
    end
    pathMap(electrodes(i)) = elecDir;
end
