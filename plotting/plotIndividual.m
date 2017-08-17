function plotIndividual(dataDir, figuresDir, animalID, whichUnits, whichFiles, ...
    whichElectrodes, figureType, sourceFormat, isparallel)
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
    fileNo = Files.fileNo(f);
    analysis = loadResults(dataDir, animalID, fileNo, sourceFormat);
    if isempty(analysis)
        warning('No analysis found for file %d', fileNo);
        continue;
    end
    unit = analysis.Params.unit;
    sourceFormat = analysis.sourceFormat;
    figuresPath = fullfile(figuresDir, animalID, unit, ...
        sourceFormat, filesep);

    % Start the parallel pool if one isn't already opened
    if isparallel && isempty(gcp('nocreate'))
        parpool; % start the parallel pool
    end
    
    switch figureType
        case 'waveforms'
            dataset = loadExperiment(dataDir, animalID, ...
                fileNo, sourceFormat);
            plotWaveforms(figuresPath, fileName, dataset);
        case 'isi'
            plotISIs(figuresPath, fileName, analysis);
        case 'tcs'
            switch analysis.Params.stimType
                case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                        'NaturalImages', 'NaturalVideos'}
                    plotMaps = 0;
                    plotTCs = 0;
                    plotBars = 1;
                    plotRasters = 1;
                case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                    plotMaps = 1;
                    plotTCs = 0;
                    plotBars = 0;
                    plotRasters = 0;
                otherwise
                    plotMaps = 0;
                    plotTCs = 1;
                    plotBars = 0;
                    plotRasters = 1;
            end
            plotAllResults(figuresPath, fileName, analysis, ...
                    whichElectrodes, plotTCs, plotBars, plotRasters, ...
                    plotMaps, 0, 0, 0, isparallel);
        case 'rasters'
            plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 1, 0, 0, 0, 0, isparallel);
        case 'lfp'
            plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 0, 0, 0, 1, 0, isparallel);
        case 'one raster'
            % clump rasters
             plotAllResults(figuresPath, fileName, analysis,...
                            whichElectrodes, 0, 0, 2, 0, 0, 0, 0, isparallel);
                        
        case 'stats'
            disp('WIP');
%             Stats = statsIndividual(dataDir, animalID, whichUnits, whichFiles, ...
%                 whichElectrode, whichCell, sourceFormat)

        case 'stimtimes'
            dataset = loadExperiment(dataDir, animalID, ...
                fileNo, sourceFormat);
            plotStimTimes(analysis.StimTimes, dataset, figuresPath, fileName);

        otherwise
            % do nothing
    end
end
