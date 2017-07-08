function [analysis] = loadResults(dataDir, animalID, unitNo, fileNo, sourceFormat)
%loadResults fetches Results and Params structs

if nargin < 5 || isempty(sourceFormat)
    sourceFormat = {'Plexon', 'Ripple'};
end
if ~iscell(sourceFormat)
    sourceFormat = cellstr(sourceFormat);
end

analysis = [];
[files, fileUnits] = findFiles(dataDir, animalID, unitNo, '*.mat', fileNo);
if ~isempty(files) && size(files, 1) == 1
    fileName = files{1};
    unit = fileUnits{1};
    filePath = fullfile(dataDir, animalID, unit, [fileName, '.mat']);
    load(filePath, 'analysis');
    % Pick which data to load
    whichData = [];
    i = 1;
    while isempty(whichData)
        if i > length(sourceFormat)
            warning('No analysis for %s', char(sourceFormat));
            return;
        end
        whichData = find(strcmp({analysis.sourceFormat}, sourceFormat{i}), ...
            1, 'last');
        i = i + 1;
    end    
    analysis = analysis(whichData);
else
    warning('File not found');
end

end

