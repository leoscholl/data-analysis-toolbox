% --- increment a filename
function FileName = NextFile (FileName)
[AnimalID, FileNo, StimName] = parseFile(FileName);
FileNo = FileNo + 1;
FileName = createFile(AnimalID, FileNo, StimName);
