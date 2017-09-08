function [ result ] = recalculateSingle( dataset, figuresDir, varargin)

p = inputParser();
p.addRequired('dataset', @isstruct);
p.addRequired('figuresDir', @ischar);
p.addOptional('whichElectrodes', [], @isnumeric);
p.addOptional('plotLFP', false, @islogical);
p.addOptional('plotFigures', true, @islogical);
p.addOptional('isparallel', true, @islogical);
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
if contains(stimType, 'ConstantCycles') || contains(stimType, 'Looming')
%     dataset.ex.binType = 'number'; % constant number of bins
    dataset.ex.binType = 'size';
else
    dataset.ex.binType = 'size'; % constant size of bins (for F1)
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
        isparallel = p.Results.isparallel;
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
        if Results.status && p.Results.plotFigures
            
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
                plotAll(figuresPath, fileName, Results, ...
                    p.Results.whichElectrodes, showFigures, isparallel);
            catch e
                fprintf(2, 'Error plotting file #%d\n', fileNo);
                rethrow(e);
            end
            
            % Plot waveforms?
            switch stimType
                case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                        'NaturalImages', 'NaturalVideos', 'spontanous'}
                    if verbose
                        disp('Plotting waveforms...');
                    end
                    plotWaveforms(figuresPath, fileName, dataset);
                
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

