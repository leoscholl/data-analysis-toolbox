% ListenRecordings - automatically recalculates after recording stops

addpath('C:\Program Files (x86)\Ripple\Trellis\Tools\neuroshare');
addpath('C:\Program Files (x86)\Ripple\Trellis\Tools\xippmex');
addpath('C:\Users\LyonLab\Dropbox\TunningCurvePlugin');
addpath('conversion');
addpath('plotting');
addpath('utils');
addpath('export_fig_toolbox');

% Parameters
ResultsDir = 'E:\Figures\';
ShowFigures = 0;
PlotWaveforms = 0;
SummaryFig = 0;
PlotLFP = 0;
PlotSpectr = 0;
MaxAttempts = 5;
 
% Check xippmex status
if ~xippmex
    xippmex('close');
    if ~xippmex
        error('Could not initialize xippmex');
    end
end

% Find trellis instance
opers = xippmex('opers');
if isempty(opers)
    xippmex('close');
    if ~xippmex
        error('Could not initialize xippmex');
    end
    opers = xippmex('opers');
    if isempty(opers)
        error('No trellis operators found');
    end
end

% Make sure xippmex is working
try
    trial = xippmex('trial', opers(1));
catch e
    xippmex('close');
    trial = xippmex('trial', opers(1));
end


RecordingFlag = 0;

while 1
    
    % Get trial status from trellis
    try
        trial = xippmex('trial', opers(1));
    catch e
        disp('Could not get the trial descriptor from xippmex');
        break;
    end
    status = trial.status;

    % Check status
    if strcmp(status,'recording')
        if RecordingFlag == 0
            disp(['Recording started for ', trial.filebase]);
        end
        RecordingFlag = 1;
        Tries = MaxAttempts;
        
    end
    
    if RecordingFlag && ~strcmp(status,'recording')
        % Trellis was recording and has stopped
        pause(1);
        
        % Parse file
        [DataPath,FileName,~] = fileparts(trial.filebase);
        [AnimalID, FileNo, StimType] = ParseFile (FileName);
        FindSlash = strfind(DataPath,'\');
        Unit = DataPath(FindSlash(end)+1:end);
        DataDir = DataPath(1:FindSlash(2));
        
        % Make sure log file is ready
        LogFile = ls(fullfile(DataPath,[FileName,'.mat']));
        AltDataPath = ['\\LYONLAB-VISUAL\',DataPath(4:end)];
        AltFile = ls(fullfile(DataPath,[FileName,'.mat']));
        if isempty(LogFile) && ~isempty(AltFile)
            % Log file hasn't been copied yet, but exists on stimulus PC
            CopyFiles ([FileName,'.mat'], AltDataPath, DataPath)
        elseif isempty(LogFile)
            % Log file doesn't exist yet, try again
            warning('Log file not found');
            if Tries > 0
                Tries = Tries - 1;
            else
                RecordingFlag = 0; % give up
            end
            continue;
        end     
        
        % Export data to matlab format
        dataExport( dataDir, [], animalID, unitNo, fileNo, 0);
                
        % Do the calculation
        Recalculate(DataDir, ResultsDir, AnimalID, Unit, FileNo, ...
            ShowFigures, PlotWaveforms, 0, SummaryFig)

        % Plot LFP
        if PlotLFP
            DataPath = fullfile(DataPath, filesep);
            [~, StimTimes, ~, ~, ~, Params] = LoadExperiment(DataDir, AnimalID,...
                Unit, FileName);
            StimSequence = Params.StimSequence;
            if ismember('TF',Params.Data.Properties.VariableNames)
                TemporalFreq = unique(Params.Data.TF);
            else
                TemporalFreq = [];
            end
            [LFPdata, SampleRate, EndTime] = load_RippleLFP(FileName, DataPath); toc;
            LFPdata = LFPdata(:,1:4:end);SampleRate = SampleRate/4;%Downsamppling data
            switch StimType
                case {'LatencyTest' , 'LaserON' , 'LaserGratings'}
                    SimpleStimulusLFP(FileName, LFPdata, StimTimes, DataPath, EndTime, SampleRate,StimType,PlotSpectr);
                case {'RFmap' , 'CatRFdetailed' ,'CatRFfast' ,'CatRFfast10x10' , 'Retinotopy'}
                    PlotMapsNewLFP(FileName, LFPdata, StimTimes, StimType, DataPath, SampleRate,EndTime);
                otherwise
                    PlotResultsLFP(FileName, LFPdata, StimTimes, StimSequence, DataPath, TemporalFreq, EndTime, SampleRate,PlotSpectr); %#ok<*NOSEM>
            end
        end
        
        RecordingFlag = 0;
    end

    % free up CPU for other things
    pause(1);
end
