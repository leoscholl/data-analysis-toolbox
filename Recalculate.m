function Recalculate(DataDir, ResultsDir, AnimalID, WhichUnits, WhichFiles, ...
    ShowFigures, PlotWaveforms, PlotLFP, SummaryFig)
%Recalculate and replot all data
% WhichUnits is an array of unit numbers to calculate
% WhichFiles is an array of file numbers to calculate

close all;
addpath('conversion');
addpath('plotting');
addpath('utils');
addpath('export_fig_toolbox');
addpath('C:\Program Files (x86)\Ripple\Trellis\Tools\neuroshare\');
tic;

% Default parameters
if nargin < 4
    WhichUnits = [];
end
if nargin < 5
    WhichFiles = [];
end
if nargin < 6 || isempty(ShowFigures)
    ShowFigures = 0;
end
if nargin < 7 || isempty(PlotWaveforms)
    PlotWaveforms = 0;
end
if nargin < 8 || isempty(PlotLFP)
    PlotLFP = 0;
end
if nargin < 9 || isempty(SummaryFig)
    SummaryFig = 0;
end

% Duration log file
DurationLogFile = 'duration_log.mat';
if ~exist('AvgDur')
    AvgDur = 30; % assume 30 seconds per file
end
if exist(DurationLogFile,'file')
    load(DurationLogFile);
else
    save(DurationLogFile, 'AvgDur');
end
Smoothing = 0.05;

% Find units
Units = FindUnits(DataDir, AnimalID, WhichUnits);

% Figure out which files need to be recalculated
[FileNames, FileUnits] = ...
    FindFiles(DataDir, AnimalID, WhichUnits, '*.nev', WhichFiles);

% Display some info about duration
nFiles = length(FileUnits);
Progress = 0;
ElapsedTime = 0;
TimeRemaining = AvgDur * (nFiles - Progress);
fprintf('There are %d files to be recalculated.\n', nFiles);
fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
    floor(TimeRemaining/60), floor(rem(TimeRemaining,60)));

% Do the recalculation
for unt = 1:length(Units(:,1))
    
    Unit = deblank(Units(unt,:));
    UnitNo = str2num(Unit(5:end));
    
    % Data comes from the DataDir, results go into the ResultsDir
    DataPath = fullfile(DataDir,AnimalID,Unit,filesep);
    ResultsPath = fullfile(ResultsDir,AnimalID,Unit,filesep);

    Files = deblank(FileNames(FileUnits == UnitNo, :));
    
    % Recalculate all files
    for f = 1:size(Files,1)
        
        tic;
        
        clear SpikeTimesMat StimTimes Waveforms StimType Params
        [~, FileName, ~] = fileparts(deblank(Files(f,:)));
        disp(FileName);
        
        try
            
            % Load experiment
            disp('Loading experiment files...');
            [SpikeTimesAll, StimTimes, Waveforms, ElectrodeNames, ...
                StimType, Params] = LoadExperiment(DataDir, AnimalID,...
                Unit, FileName);
            
            % Plot waveforms?
            if PlotWaveforms && ~isempty(Waveforms)
                disp('Plotting waveforms...');
                PlotWaveforms(ResultsPath, FileName, Waveforms, ElectrodeNames);
            end
            
            % Number of bins or size of bins?
            switch StimType
                case {'VelocityConstantCycles', 'VelocityConstantCyclesBar',...
                        'Looming', 'ConstantCycles'}
                    Params.BinType = 'number'; % constant number of bins
                otherwise
                    Params.BinType = 'size'; % constant size of bins (for F1)
            end
            
            % What to plot?
            switch StimType
                case {'LatencyTest', 'LaserON', 'LaserGratings', ...
                        'NaturalImages', 'NaturalVideos'}
                    PlotMaps = 0;
                    PlotTCs = 0;
                    PlotBars = 1;
                    PlotRasters = 1;
                case {'RFmap', 'CatRFdetailed', 'CatRFfast', 'CatRFfast10x10'}
                    PlotMaps = 1;
                    PlotTCs = 0;
                    PlotBars = 0;
                    PlotRasters = 1;
                otherwise
                    PlotMaps = 0;
                    PlotTCs = 1;
                    PlotBars = 0;
                    PlotRasters = 1;
            end
                    
            
            % Do the analysis / plotting
            switch StimType
                case {'OriLowHighTwoApertures', 'CenterNearSurround'}
                    fprintf(2, 'Center surround not yet implemented.\n');
                otherwise
                    disp('plotting...');
                    PlotResults(ResultsPath, FileName, StimType, ...
                        Params, StimTimes, SpikeTimesAll, ElectrodeNames, ...
                        PlotTCs, PlotBars, PlotRasters, PlotMaps, ...
                        SummaryFig, PlotLFP, ShowFigures)
            end
            
        catch e
            disp(['This file didnt work ',FileName])
            warning(getReport(e,'extended','hyperlinks','off'),'Error');
        end
        close all;
        
        % Update duration log
        FileDuration = toc;
        Progress = Progress + 1;
        ElapsedTime = ElapsedTime + FileDuration;
        AvgDur = Smoothing * FileDuration + (1 - Smoothing) * AvgDur;
        save(DurationLogFile, 'AvgDur', '-append');
        
        % Display time remaining
        fprintf('This file took %d minutes and %d seconds\n', ...
            floor(FileDuration/60), floor(rem(FileDuration,60)));
        TimeRemaining = AvgDur * (nFiles - Progress);
        fprintf('Time remaining: %d minutes and %d seconds\n\n', ...
            floor(TimeRemaining/60), floor(rem(TimeRemaining,60)));
    end
end

fprintf('Total elapsed time: %d minutes and %d seconds\n', ...
floor(ElapsedTime/60), floor(rem(ElapsedTime,60)));

