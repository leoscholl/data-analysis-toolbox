% --- parse a filename
function [AnimalID, FileNo, StimType] = ParseFile (FileName)
% FileName  should be a string of the format AnimalID#FileNo[StimName]
%
% AnimalID  string for the animal ID
% FileNo    integer for the file number
% StimName  string describing the stimulus choice

FindCross = strfind(FileName,'#');
FindBracket = strfind(FileName,'[');
FindEndBracket = strfind(FileName,']');
FileNo = str2num(FileName(FindCross+1:FindBracket-1));
StimType = FileName(FindBracket+1:FindEndBracket-1);
AnimalID = FileName(1:FindCross-1);

if isempty(FileNo)
    FileNo = NaN;
end