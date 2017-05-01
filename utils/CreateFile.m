
% --- create a filename from parts
function FileName = CreateFile (AnimalID, FileNo, StimType)
% AnimalID  string for the animal ID
% FileNo    integer for the file number
% StimName  string describing the stimulus choice

FileName = strcat(AnimalID,'#',num2str(FileNo),'[',StimType,']');

