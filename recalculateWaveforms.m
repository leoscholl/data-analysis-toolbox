function recalculateWaveforms(dataDir, resultsDir, animalID, whichUnits, ...
    whichFiles, whichElectrodes)
%recalculateWaveforms Plots waveforms for each file
%   Use this to add waveforms for files that already have been plotted

% Default parameters
if nargin < 4
    whichUnits = [];
end
if nargin < 5
    whichFiles = [];
end
if nargin < 6
    whichElectrodes = [];
end

% Find appropriate files
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*].nev', whichFiles);


if isempty(Files)
    warning(['No files found in ', dataDir]);
end

% Plot the waveforms
for f = 1:size(Files,1)
    
    unit = Files.unit{f};
    dataPath = fullfile(dataDir,animalID,unit,filesep);
    resultsPath = fullfile(resultsDir,animalID,unit,filesep);
    
    fileName = Files.fileName{f};
    disp(fileName);
    
    Electrodes = loadRippleWaveforms(dataPath, fileName, [], ...
        whichElectrodes);
    if ~isempty(Electrodes) && ~isempty(Electrodes.waveforms)
        disp('Plotting waveforms...');
        if size(Electrodes.waveforms,1) ~= size(Electrodes.spikes,1)
            error('Not enough waveforms');
        end
        
        plotWaveforms(dataPath, resultsPath, fileName, Electrodes);
    end
end
end

