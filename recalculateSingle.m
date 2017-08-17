function [ result ] = recalculateSingle( dataset, figuresDir, varargin)

p = inputParser();
p.addRequired('dataset', @isstruct);
p.addRequired('figuresDir', @ischar);
p.addOptional('whichElectrodes', [], @isnumeric);
p.addOptional('summaryFig', false, @islogical);
p.addOptional('plotLFP', false, @islogical);
p.addOptional('plotFigures', true, @islogical);
p.addOptional('verbose', false, @islogical);
p.parse(dataset, figuresDir, varargin{:});
dataset = p.Results.dataset;
figuresDir = p.Results.figuresDir;
verbose = p.Results.verbose;

tic;
result.status = 0;
result.fileDuration = 0;

if ~isfield(dataset, 'ex') || isempty(dataset.ex)
    return;
end

fileNo = dataset.ex.expNo;
stimType = dataset.ex.stimType;

if verbose
    animalID = dataset.ex.animalID;
    fileName = createFileName(animalID, fileNo, stimType);
    disp(fileName);
end

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
            'NaturalImages', 'NaturalVideos', 'spontanous'}
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
        
        % Binning and making rastergrams
        if verbose
            disp('analyzing...');
        end
        isparallel = ~p.Results.summaryFig;
        try
            Results = analyze(dataset, p.Results.whichElectrodes, verbose, isparallel);
        catch e
            fprintf(2, 'Error doing calculations for file #%d\n', fileNo);
            rethrow(e);
        end
        
        if verbose
            disp('saving results...');
        end
        
        % Save results
        if ~Results.status
            warning('file #%d - %s', fileNo, Results.error);
            result.fileDuration = toc;
            return;
        else
            Results.sourceFormat = dataset.sourceformat;
            Results.source = dataset.filepath;
            saveResults(Results);
        end
        
        unit = Results.Params.unit;
        animalID = Results.Params.animalID;
        fileName = createFileName(animalID, fileNo, stimType);
        figuresPath = fullfile(figuresDir,animalID,unit,filesep);
        
        if Results.StimTimes.hasError
            plotStimTimes(Results.StimTimes, dataset, figuresPath, fileName);
            fprintf(2, 'Error in %s: %s\n', fileName, Results.StimTimes.msg);
        elseif verbose
            msg = strrep(Results.StimTimes.msg,'. ', '.\n');
            fprintf([msg, '\n']);
        end
        
        % Plotting tuning curves and maps
        if p.Results.plotFigures
            
            % Append source format to figures directory
            figuresPath = fullfile(figuresPath, Results.sourceFormat, filesep);
            
            % Delete any old figures
            if verbose
                disp('deleting old figures...');
            end
            unitNo = sscanf(unit, 'Unit%d');
            deleteFitFiles(figuresDir, animalID, unitNo, fileNo, ...
                Results.sourceFormat);
            
            % Plot tuning curves, rasters, and maps
            if verbose
                disp('plotting...');
            end
            showFigures = 0;
            try
                plotAllResults(figuresPath, fileName, Results, ...
                    p.Results.whichElectrodes, plotTCs, plotBars, plotRasters, ...
                    plotMaps, p.Results.summaryFig, p.Results.plotLFP, ...
                    showFigures);
            catch e
                fprintf(2, 'Error plotting file #%d\n', fileNo);
                rethrow(e);
            end
            
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

result.fileDuration = toc;
result.status = 1;
end

