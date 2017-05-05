% --- create a filename from parts
function fileName = createFileName (animalID, fileNo, stimType)
% AnimalID  string for the animal ID
% FileNo    integer for the file number
% StimName  string describing the stimulus choice

fileName = strcat(animalID,'#',num2str(fileNo),'[',stimType,']');

