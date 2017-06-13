function [fileNames, fileUnits, Files] = findFiles(baseDir, animalID, whichUnits, ...
    fileString, whichFiles)
%FindFiles
%
% Unit is optional, can be number or string
% FileString is optional
% WhichFiles is optional
%
% Files is a list of n output file strings (with padding)
% FileUnits is a list of length n that lists the unit string for each file
%   (with padding)

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
    dataPath = fullfile(baseDir,animalID,whichUnits{i},filesep);
    newFiles = dir([dataPath,fileString]);
    newFiles = newFiles(~vertcat(newFiles.isdir)); % just for good measure
    newFiles = cellfun(@stripFileName, {newFiles.name}, 'UniformOutput', false);
    newFiles = unique(newFiles);
    [~, newFileNos, newStimTypes] = cellfun(@parseFileName, newFiles, 'UniformOutput', false);
    fileNames = [fileNames; newFiles', newFileNos', newStimTypes', ...
        repmat(whichUnits(i),length(newFiles),1), ...
        repmat({str2num(whichUnits{i}(5:end))},length(newFiles),1)];
end

if isempty(fileNames)
    warning('No files found');
end

if ~isempty(fileNames) && ~isempty(whichFiles)
    
    % Remove files that aren't in WhichFiles
    fileNames = fileNames(ismember(vertcat(fileNames{:,2}), whichFiles),:);
end

% Sort files
[~,IX] = sort(vertcat(fileNames{:,2}));
if ~isempty(fileNames)
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