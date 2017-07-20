% --- parse a filename
function [animalID, fileNo, stimType] = parseFileName (fileName)
% FileName  should be a string of the format AnimalID#FileNo[StimName]
%
% AnimalID  string for the animal ID
% FileNo    integer for the file number
% StimName  string describing the stimulus choice

% pat = '^[A-Z]*\d{4}';
% animalID = regexp(fileName, pat, 'match');
% if isempty(animalID)
%     animalID = '';
% else
%     animalID = animalID{1};
% end
% 
% pat = '#(\d*)';
% fileNo = regexp(fileName, pat, 'tokens');
% if isempty(fileNo)
%     fileNo = NaN;
% else
%     fileNo = str2double(fileNo{1}{1});
% end
% 
% pat = '\[(\w*)\]';
% stimType = regexp(fileName, pat, 'tokens');
% if isempty(stimType)
%     stimType = '';
% else
%     stimType = stimType{1}{1};
% end

animalID = '';
fileNo = NaN;
stimType = '';

fileName = strrep(fileName, ']', ' ');
[nums, c] = sscanf(fileName, '%c%4d#%d[%s*');
if c < 4; return; end;
animalID = [char(nums(1)), num2str(nums(2))];
fileNo = nums(3);
stimType = char(nums(4:end))';