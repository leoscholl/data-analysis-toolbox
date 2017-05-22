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

[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*]*', whichFiles);

for i=1:size(Files,1)
    fileName = Files.fileName{i};
    unit = Files.unit{i};
    dataPath = fullfile(dataDir, animalID, unit);
    destPath = fullfile(copyDir, animalID, unit);
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
        Ripple.LFP = loadRippleAnalog(dataPath, fileName, 'lfp');
        Ripple.AnalogIn = loadRippleAnalog(dataPath, fileName, 'analog');
        Ripple.Events = loadRippleEvents(dataPath,fileName);
        m.Ripple = Ripple;
    elseif ~isfield(m.Ripple, 'Events')
        Ripple = m.Ripple;
        Ripple.Events = loadRippleEvents(dataPath,fileName);
        m.Ripple = Ripple;
    elseif ~isfield(m.Ripple, 'Electrodes')
        Ripple = m.Ripple;
        Ripple.Electrodes = loadRippleSpikes(dataPath,fileName);
        m.Ripple = Ripple;
    elseif ~isfield(m.Ripple, 'LFP')
        Ripple = m.Ripple;
        Ripple.LFP = loadRippleAnalog(dataPath, fileName, 'lfp');
        m.Ripple = Ripple;
    elseif ~isfield(m.Ripple, 'AnalogIn')
        Ripple = m.Ripple;
        Ripple.AnalogIn = loadRippleAnalog(dataPath, fileName, 'analog');
        m.Ripple = Ripple;
    end
    
    if isempty(whos(m,'Params'))
        % Redo Params
        m.Params = loadParams(dataPath, fileName);
    end
    
    % Finally, copy anything that exists
    if ~isempty(copyDir)
        copyFiles ([fileName,'-export.mat'], dataPath, destPath);
    end
end