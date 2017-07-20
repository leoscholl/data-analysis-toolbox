function [analysis] = loadResults(dataDir, animalID, fileNo, sourceFormat)
%loadResults fetches Results and Params structs

if nargin < 4 || isempty(sourceFormat)
    sourceFormat = {'WaveClus', 'Plexon', 'Ripple'};
end
if ~iscell(sourceFormat)
    sourceFormat = cellstr(sourceFormat);
end

analysis = [];
[~, ~, Files] = findFiles(dataDir, animalID, [], '*.mat', fileNo);
if size(Files, 1) > 1
    warning('Too many files with the same file number');
    return;
elseif isempty(Files)
    warning('File no %d not found', fileNo);
    return;
end
filePath = Files.rawFileName{1};

if exist(filePath, 'file')
    load(filePath, 'analysis');
    if isempty(analysis)
        warning('No analysis found');
        return;
    end
    % Pick which data to load
    whichData = [];
    i = 1;
    while isempty(whichData)
        if i > length(sourceFormat) && length(sourceFormat) > 1
            warning('No analysis found');
            analysis = [];
            return;
        elseif i > length(sourceFormat)
            warning('No analysis for %s', char(sourceFormat));
            analysis = [];
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

