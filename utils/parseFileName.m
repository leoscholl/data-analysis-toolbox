% --- parse a filename
function [animalID, fileNo, stimType] = parseFileName (fileName)
% FileName  should be a string of the format AnimalID#FileNo[StimName]
%
% AnimalID  string for the animal ID
% FileNo    integer for the file number
% StimName  string describing the stimulus choice

pat = '^[A-Z]*\d{4}';
animalID = regexp(fileName, pat, 'match');
if isempty(animalID)
    warning('Incorrectly formatted AnimalID');
    animalID = '';
else
    animalID = animalID{1};
end

pat = '#(\d*)';
fileNo = regexp(fileName, pat, 'tokens');
if isempty(fileNo)
    warning('Incorrectly formatted FileNo');
    fileNo = NaN;
else
    fileNo = str2double(fileNo{1}{1});
end

pat = '\[(\w*)\]';
stimType = regexp(fileName, pat, 'tokens');
if isempty(stimType)
    warning('Incorrectly formatted StimType');
    stimType = '';
else
    stimType = stimType{1}{1};
end
