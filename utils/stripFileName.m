% --- strip a filename (remove non-essential characters)
function fileName = stripFileName (fileName)
% FileName  should be a string of the format AnimalID#FileNo[StimName]

[animalID, fileNo, stimType] = parseFileName(fileName);
fileName = createFileName(animalID, fileNo, stimType);