function plotIndividual(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    searchString, figureType, sourceFormats, isparallel)
%plotIndividual plot and individual figure for one file

whichElectrodes = []; % TODO

% Figure out which files need to be recalculated
[~, ~, Files] = ...
    findFiles(dataDir, animalID, whichUnits, [searchString, '.mat'], whichFiles);

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
    fileNo = Files.fileNo(f);
    analysis = loadResults(dataDir, animalID, fileNo, sourceFormats);
    if isempty(analysis)
        warning('No analysis found for file %d', fileNo);
        continue;
    end
    unit = analysis.Params.unit;
    sourceFormat = analysis.sourceFormat;
    figuresPath = fullfile(figuresDir, animalID, unit, ...
        sourceFormat, filesep);
    
    switch figureType
        case 'waveforms'
            dataset = loadExperiment(dataDir, animalID, ...
                fileNo, sourceFormat);
            plotWaveforms(figuresPath, fileName, dataset);
        case 'isi'
            plotISIs(figuresPath, fileName, analysis);
        case 'tcs'
            
            % Delete old files for this source format
            deleteFitFiles(figuresDir, animalID, analysis.Params.unitNo, fileNo, sourceFormat)
            
            % Plot new ones
            plotAll(figuresPath, fileName, analysis, ...
                    whichElectrodes, false, isparallel);
        case 'rasters'
            plotFun = {@plotRastergrams};

            plotSpikeData(figuresPath, fileName, analysis,...
                plotFun, whichElectrodes, false, isparallel)
        case 'lfp'
            disp('WIP');
        case 'one raster'
            % clump rasters
            plotFun = {@plotRastersAll};
            
            plotSpikeData(figuresPath, fileName, analysis,...
                plotFun, whichElectrodes, false, isparallel)
        case 'spike spectrogram'
            plotFun = {@plotSpectrogram};
            
            plotSpikeData(figuresPath, fileName, analysis,...
                plotFun, whichElectrodes, false, isparallel)
        case 'stats'
            disp('WIP');
%             Stats = statsIndividual(dataDir, animalID, whichUnits, whichFiles, ...
%                 whichElectrode, whichCell, sourceFormat)

        case 'stimtimes'
            figuresPath = fullfile(figuresDir, animalID, unit, filesep);
            dataset = loadExperiment(dataDir, animalID, ...
                fileNo, sourceFormat);
            plotStimTimes(analysis.StimTimes, dataset, figuresPath, fileName);

        otherwise
            % do nothing
    end
end
