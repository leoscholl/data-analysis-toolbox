function [Params, Results] = loadResults(resultsDir, animalID, unitNo, fileNo)
%loadResults fetches Results and Params structs

Params = [];
Results = [];
[files, fileUnits] = findFiles(resultsDir, animalID, unitNo, '*-results.mat', fileNo);
if ~isempty(files) && size(files, 1) == 1
    fileName = files{1};
    unit = fileUnits{1};
    filePath = fullfile(resultsDir, animalID, unit, [fileName, '-results.mat']);
    load(filePath);
else
    warning('File not found');
end

end

