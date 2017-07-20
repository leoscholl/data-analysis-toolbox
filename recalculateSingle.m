function [ fileDuration ] = recalculateSingle( dataDir, figuresDir, animalID, ...
    unit, fileName, sourceFormat, whichElectrodes, ...
    summaryFig, plotLFP, plotFigures, verbose)

tic;
fileDuration = 0;

[~, fileNo, stimType] = parseFileName(fileName);
if verbose
    disp('Loading experiment files...');
end

dataset = loadExperiment(dataDir, animalID, fileNo, sourceFormat);

% Number of bins or size of bins?
switch stimType
    case {'VelocityConstantCycles', 'VelocityConstantCyclesBar',...
            'Looming', 'ConstantCycles'}
        dataset.ex.binType = 'number'; % constant number of bins
    otherwise
        dataset.ex.binType = 'size'; % constant size of bins (for F1)
end

% What to plot?
switch stimType
    case {'LatencyTest', 'LaserON', 'LaserGratings', ...
            'NaturalImages', 'NaturalVideos'}
        plotMaps = 0;
        plotTCs = 0;
        plotBars = 1;
        plotRasters = 1;
        
        plotWFs = 1;
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
switch stimType
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
        Results = analyze(dataset, whichElectrodes, verbose);

        % Save results
        if ~Results.status
            warning('%s - %s', fileName, Results.error);
            fileDuration = toc;
            return;
        else
            Results.sourceFormat = dataset.sourceformat;
            Results.source = dataset.source;
            saveResults(Results);
        end
        
        figuresPath = fullfile(figuresDir,animalID,unit,filesep);
        
        % Check the stim times
        if Results.StimTimes.hasError
            plotStimTimes(Results.StimTimes, dataset, figuresPath, fileName);
            fprintf(2, 'Error in %s: %s\n', fileName, Results.StimTimes.msg);
        elseif verbose
            msg = strrep(Results.StimTimes.msg,'. ', '.\n');
            fprintf([msg, '\n']);
        end
        
        % Plotting tuning curves and maps
        if plotFigures
            if verbose
                disp('plotting...');
            end

            % Append source format to figures directory
            figuresPath = fullfile(figuresPath, Results.sourceFormat, filesep);
            
            showFigures = 0;
            plotAllResults(figuresPath, fileName, Results, ...
                whichElectrodes, plotTCs, plotBars, plotRasters, ...
                plotMaps, summaryFig, plotLFP, showFigures);
            
            
            % Plot waveforms?
            if plotWFs
                if verbose
                    disp('Plotting waveforms...');
                end
                plotWaveforms(figuresPath, fileName, dataset);
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

