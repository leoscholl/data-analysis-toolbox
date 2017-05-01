function [FileNames, FileUnits] = FindFiles(Dir, AnimalID, Unit, FileString, WhichFiles)
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
    WhichFiles = [];
end
if nargin < 4
    FileString = '';
end
if nargin < 3
    Unit = [];
end

if isnumeric(Unit)
    Unit = FindUnits(Dir, AnimalID, Unit);
end

FileNames = [];
FileUnits = [];
Padding = 100;
for i = 1:size(Unit,1)
    DataPath = fullfile(Dir,AnimalID,Unit(i,:),filesep);
    NewFiles = ls([DataPath,FileString]);
    FileNames = [FileNames; NewFiles ...
        repmat(' ', size(NewFiles,1), Padding-size(NewFiles,2))];
    FileUnits = [FileUnits; repmat(str2num(Unit(i,5:end)), size(NewFiles,1), 1)];
end

if isempty(FileNames)
    warning('No files found');
end

if ~isempty(FileNames) && ~isempty(WhichFiles)
    
    % Remove files that aren't in WhichFiles
    FileNo = [];
    for i = 1:size(FileNames,1)
        [~, FileNo(i), ~] = ParseFile(FileNames(i,:));
    end
    FileNames = FileNames(ismember(FileNo, WhichFiles),:);
    FileUnits = FileUnits(ismember(FileNo, WhichFiles),:);
end

% Sort files
FileNo = [];
for i = 1:size(FileNames,1)
    [~, FileNo(i), ~] = ParseFile(FileNames(i,:));
end
[~,IX] = sort(FileNo);
FileNames = FileNames(IX,:);
FileUnits = FileUnits(IX,:);

end