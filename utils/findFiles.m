function [fileNames, fileUnits, Files] = findFiles(baseDir, animalID, whichUnits, ...
    fileString, whichFiles)
%findFiles
%
% Unit is optional, can be number or string
% fileString is optional
% whichFiles is optional
%
% fileNames is a list of n output file strings (with padding)
% fileUnits is a list of length n that lists the unit string for each file
%   (with padding)
% Files is a table with all the information
%   - fileName
%   - fileNo
%   - stimType
%   - unit
%   - unitNo

narginchk(2,5);

if nargin < 5
    whichFiles = [];
end
if nargin < 4
    fileString = '';
end
if nargin < 3
    whichUnits = [];
end

if ~isnumeric(whichUnits) || ~isnumeric(whichFiles)
    error('whichFiles only accepts numeric input');
end

whichUnits = findUnits(baseDir, animalID, whichUnits);
fileNames = {};
for i = 1:length(whichUnits)
    
    % Search for files
    dataPath = fullfile(baseDir,animalID,whichUnits{i},filesep);
    newFiles = dir([dataPath,fileString]);
    newFiles = newFiles(~vertcat(newFiles.isdir)); % just for good measure
    newFiles = cellfun(@stripFileName, {newFiles.name}, 'UniformOutput', false);
    newFiles = unique(newFiles);
    
    % Remove any files that aren't correctly formatted
    [~, newFileNos, newStimTypes] = cellfun(@parseFileName, newFiles, 'UniformOutput', false);
    valid = cellfun(@(x, y)~isnan(x) && ~isempty(y), newFileNos, newStimTypes);
    newFiles = newFiles(valid);
    newFileNos = newFileNos(valid);
    newStimTypes = newStimTypes(valid);

    % List all the files
    fileNames = [fileNames; newFiles', newFileNos', newStimTypes', ...
        repmat(whichUnits(i),length(newFiles),1), ...
        repmat({str2num(whichUnits{i}(5:end))},length(newFiles),1)];
end

if ~isempty(fileNames) && ~isempty(whichFiles)
    
    % Remove files that aren't in whichFiles
    fileNames = fileNames(ismember(vertcat(fileNames{:,2}), whichFiles),:);
end

% Sort files
if ~isempty(fileNames)
    [~,IX] = sort(vertcat(fileNames{:,2}));
    Files = cell2table(fileNames(IX,:));
    fileUnits = fileNames(IX,4);
    fileNames = fileNames(IX,1);
else
    Files = table(cell(0),[],cell(0),cell(0),[]);
    fileUnits = '';
    fileNames = '';
end
Files.Properties.VariableNames = {'fileName','fileNo','stimType','unit','unitNo'};

end