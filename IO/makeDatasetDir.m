function dir = makeDatasetDir(dataset, basePath)
if ~isempty(dataset.ex.RecordSession) && ~isempty(dataset.ex.RecordSite)
    session = sprintf('%s_%s',dataset.ex.RecordSession,dataset.ex.RecordSite);
else
    session = sprintf('%s%s',dataset.ex.RecordSession,dataset.ex.RecordSite);
end
dir = fullfile(basePath,dataset.ex.Subject_ID,session);
if ~exist(dir, 'dir')
    mkdir(dir);
end