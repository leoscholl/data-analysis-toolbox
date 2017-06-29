function dataExportNA( dataDir, destDir, animalID, whichUnits, whichFiles, overwrite)
%DataExport exports specified units and directories from DataDir to CopyDir

narginchk(3,6);

if nargin < 6 || isempty(overwrite)
    overwrite = false;
end
if nargin < 5
    whichFiles = [];
end
if nargin < 4
    whichUnits = [];
end

[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*].n*', whichFiles);

% if isempty(gcp('nocreate'))
%     parpool;
% end

for i=1:size(Files,1)
    fileName = Files.fileName{i};
    unit = Files.unit{i};
    dataPath = fullfile(dataDir, animalID, unit);
    dataFile = fullfile(dataPath, [fileName, '.nev']);
    destPath = fullfile(destDir, animalID, unit);
    exportFile = fullfile(destPath, [fileName, '.mat']);
      
    disp(['exporting ', fileName]);
    
    % Delete the file if we are overwriting
    if overwrite && exist(exportFile,'file')
        delete(exportFile);
    elseif exist(exportFile,'file')
        continue;
    end

    % Export anything that's not already there
    if ~exist(destPath, 'dir')
        mkdir(destPath);
    end
    
    % Use NeuroAnalysis export
    sourceformat = 'Ripple';
    isparallel = 1;
    doplotting = 0;
    [ result ] = NeuroAnalysis.Base.EvalFun('NeuroAnalysis.IO.Export', ...
        {dataFile, destPath,sourceformat,isparallel,doplotting} );
    if ~result.status
        warning(result.source);
    end
end