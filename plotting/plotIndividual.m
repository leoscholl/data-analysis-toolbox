function plotIndividual(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    whichElectrodes, figureType, sourceFormat)
%plotIndividual plot and individual figure for one file

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, '*.mat', whichFiles);

% Display some info about duration
nFiles = size(Files,1);
if nFiles < 1
    return;
end
fprintf('Plotting %s for %d files...\n', figureType, nFiles);

% Plot for all files
for f = 1:size(Files,1)
    
    fileName = Files.fileName{f};
    disp(fileName);
    unit = Files.unit{f};
    unitNo = Files.unitNo(f);
    fileNo = Files.fileNo(f);
    figuresPath = fullfile(figuresDir, animalID, unit);
    analysis = loadResults(dataDir, animalID, unitNo, fileNo, ...
        sourceFormat);

    % Start the parallel pool if one isn't already opened
    if isempty(gcp('nocreate'))
        parpool; % start the parallel pool
    end
    
    switch figureType
        case 'waveforms'
            Electrodes = loadExperiment(dataDir, animalID, unit, ...
                fileName, sourceFormat);
            plotWaveforms(figuresPath, fileName, Electrodes);
        case 'isi'
            plotISIs(figuresPath, fileName, analysis);
        case 'rasters'
            plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 1, 0, 0, 0, 0);
        case 'lfp'
            plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 0, 0, 0, 1, 0);
        case 'one raster'
            % clump rasters
             plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 2, 0, 0, 0, 0);

    end
end
