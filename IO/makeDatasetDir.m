function dir = makeDatasetDir(id, site, session, basePath)
if ~isempty(session) && ~isempty(site)
    session = sprintf('%s_%s',session,site);
else
    session = sprintf('%s%s',session,site);
end
dir = fullfile(basePath,id,session);
if ~exist(dir, 'dir')
    mkdir(dir);
end