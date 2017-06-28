function [Params, Results] = loadResults(dataDir, animalID, unitNo, fileNo)
%loadResults fetches Results and Params structs

Params = [];
Results = [];
[files, fileUnits] = findFiles(dataDir, animalID, unitNo, '*-export.mat', fileNo);
if ~isempty(files) && size(files, 1) == 1
    fileName = files{1};
    unit = fileUnits{1};
    filePath = fullfile(dataDir, animalID, unit, [fileName, '-export.mat']);
    load(filePath);
else
    warning('File not found');
end

end

