function dataExport( dataDir, destDir, animalID, whichUnits, whichFiles, overwrite)
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

parfor i=1:size(Files,1)
    fileName = Files.fileName{i};
    unit = Files.unit{i};
    dataPath = fullfile(dataDir, animalID, unit);
    destPath = fullfile(destDir, animalID, unit);
    exportFile = fullfile(destPath, [fileName, '-export.mat']);
      
    disp(['exporting ', fileName]);
    
    % Delete the file if we are overwriting
    if overwrite && exist(exportFile,'file')
        delete(exportFile);
    end

    % Export anything that's not already there
    if ~exist(destPath, 'dir')
        mkdir(destPath);
    end
    m = matfile(exportFile,'Writable',true);
    if isempty(whos(m,'Ripple'))
        % Spikes, LFP, and Events
        Ripple = [];
        Ripple.Electrodes = loadRippleWaveforms(dataPath,fileName);
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
        Ripple.Electrodes = loadRippleWaveforms(dataPath,fileName);
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
end