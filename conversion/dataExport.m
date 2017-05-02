function dataExport( dataDir, copyDir, animalID, whichUnits, whichFiles, overwrite)
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

[fileNames, fileUnits] = ...
    FindFiles(dataDir, animalID, whichUnits, '*.nev', whichFiles);

for i=1:size(fileNames,1)
    [~, fileName, ~] = fileparts(deblank(fileNames(i,:)));
    unitNo = fileUnits(i,:);
    [animalID, fileNo, ~] = ParseFile(fileName);
    dataPath = fullfile(dataDir, animalID, ['Unit',num2str(unitNo)]);
    destPath = fullfile(copyDir, animalID, ['Unit',num2str(unitNo)]);
    exportFile = fullfile(dataPath, [fileName, '-export.mat']);
      
    disp(['exporting ', fileName]);
    
    % Delete the file if we are overwriting
    if overwrite && exist(exportFile,'file')
        delete(exportFile);
    end

    % Export anything that's not already there
    m = matfile(exportFile,'Writable',true);
    if isempty(whos(m,'Ripple'))
        % Spikes, LFP, and Events
        Ripple = [];
        Ripple.Electrodes = loadRippleSpikes(dataPath,fileName);
        Ripple.LFP = loadRippleLFP(dataPath, fileName);
        Ripple.Events = loadRippleEvents(dataPath,fileName);
        m.Ripple = Ripple;
    elseif ~isfield(m.Ripple, 'Events')
        m.Ripple.Events = loadRippleEvents(dataPath,fileName);
    elseif ~isfield(m.Ripple, 'Electrodes')
        m.Ripple.Electrodes = loadRippleSpikes(dataPath,fileName);
    elseif ~isfield(m.Ripple, 'LFP')
        m.Ripple.LFP = loadRippleLFP(dataPath,fileName);
    end
    
    if isempty(whos(m,'Params'))
        % Redo Params
        m.Params = loadParams(dataPath, fileName);
    end
    
    % Finally, copy anything that exists
    if ~isempty(copyDir)
        CopyFiles ([fileName,'-export.mat'], dataPath, destPath);
    end
end