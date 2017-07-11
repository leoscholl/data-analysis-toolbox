function [ fileDuration ] = recalculateSingle( dataDir, figuresDir, animalID, ...
    unit, fileName, sourceFormat, whichElectrodes, ...
    summaryFig, plotLFP, plotFigures, verbose)

tic;
fileDuration = 0;

dataPath = fullfile(dataDir,animalID,unit,filesep);
figuresPath = fullfile(figuresDir,animalID,unit,filesep);
if verbose
    disp('Loading experiment files...');
end

[Electrodes, Params, StimTimes, LFP, AnalogIn, sourceFormatOut, ...
    hasError, msg] = ...
    loadExperiment(dataDir, animalID, unit, fileName, sourceFormat);

if hasError
    plotStimTimes(StimTimes, AnalogIn, figuresPath, fileName, msg);
    fprintf(2, 'Error in %s: %s\n', fileName, msg);
elseif verbose
    disp(msg);
end


if hasError > 1
    warning('Loading experiment failed. Skipping %s.', fileName);
    return;
end

% Number of bins or size of bins?
switch Params.stimType
    case {'VelocityConstantCycles', 'VelocityConstantCyclesBar',...
            'Looming', 'ConstantCycles'}
        Params.binType = 'number'; % constant number of bins
    otherwise
        Params.binType = 'size'; % constant size of bins (for F1)
end

% What to plot?
switch Params.stimType
    case {'LatencyTest', 'LaserON', 'LaserGratings', ...
            'NaturalImages', 'NaturalVideos'}
        plotMaps = 0;
        plotTCs = 0;
        plotBars = 1;
        plotRasters = 1;
        if strcmp(animalID, 'R1702')
            plotWFs = 0;
        else
            plotWFs = 1;
        end
        plotISI = 1;
    case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
        plotMaps = 1;
        plotTCs = 0;
        plotBars = 0;
        plotRasters = 0;
        plotWFs = 0;
        plotISI = 0;
    otherwise
        plotMaps = 0;
        plotTCs = 1;
        plotBars = 0;
        plotRasters = 1;
        plotWFs = 0;
        plotISI = 0;
end


% Do the analysis / plotting
switch Params.stimType
    case {'OriLowHighTwoApertures', 'CenterNearSurround'}
        fprintf(2, 'Center surround not yet implemented.\n');
    otherwise
        
        if ~summaryFig && isempty(gcp('nocreate')) && isempty(getCurrentTask())
            parpool; % start the parallel pool
        end
        
        % Binning and making rastergrams
        if verbose
            disp('analyzing...');
        end
        Results = analyze(dataPath, fileName, sourceFormatOut, ...
            Params, StimTimes, Electrodes, whichElectrodes, verbose);
        
        % Plotting tuning curves and maps
        if plotFigures
            if verbose
                disp('plotting...');
            end
            showFigures = 0;
            plotAllResults(figuresPath, fileName, Results, ...
                whichElectrodes, plotTCs, plotBars, plotRasters, ...
                plotMaps, summaryFig, plotLFP, showFigures);
            
            
            % Plot waveforms?
            if plotWFs
                if verbose
                    disp('Plotting waveforms...');
                end
                plotWaveforms(figuresPath, fileName, Electrodes);
            end
            
            % Plot ISIs?
            if plotISI && ~isempty(Results)
                if verbose
                    disp('Plotting ISIs...');
                end
                plotISIs(figuresPath, fileName, Results);
            end
        end
end

fileDuration = toc;
end

