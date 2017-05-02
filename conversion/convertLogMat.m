function Params = convertLogMat( dataPath, fileName )
%ConvertLogMats Reads the log matrix from visstim and creates a new
%parameters file

% Location for alternate sequences
if ispc
    home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
else
    home = getenv('HOME');
end
seqDir = fullfile(home,'Dropbox','TunningCurvePlugin');
altSeqDir = fullfile(home,'Dropbox','TunningCurvePlugin','NewSeq');
addpath(fullfile(home,'Dropbox','TunningCurvePlugin'));

filePath = fullfile(dataPath, fileName);

Params = [];
fileVars = who('-file', filePath);
vars = {'data','GridSize',...
    'MonitorDistance','MonRes','MonSize','RFposition'};
if ismember('PPD',fileVars)
    vars{end+1} = 'PPD';
end
if ismember('StimInterval',fileVars)
    vars{end+1} = 'StimInterval';
else
    StimInterval = 1.5; % probably wrong...
end
if ismember('StimDuration',fileVars)
    vars{end+1} = 'StimDuration';
else
    StimDuration = 0.5; % probably wrong...
end
load(filePath, vars{:});
[AnimalID, ExpNo, StimType] = ParseFile(fileName);
Params.ExpNo = ExpNo;
Params.AnimalID = AnimalID;
Params.StimType = StimType;
pathParts = strsplit(dataPath,filesep);
Params.Unit = char(pathParts{end});

% Monitor resolution, size, PPD, etc.
if exist('MonRes','var')
    MonRes = cellfun(@str2num,regexp(MonRes,'\d+','match'));
else
    MonRes = [1920 1080];
end
if exist('PPD', 'var')
    Params.PPD = PPD;
    Params.MonitorSize = NaN;
elseif ischar(MonSize)
    Params.MonitorSize = MonSize; % needs fixing
else
    Params.MonitorSize = MonSize;
    Resolution.width = MonRes(2);
    Resolution.height = MonRes(1);
    Params.PPD = monitorPPD(Resolution, MonSize, MonitorDistance);
end
Params.GridSize = GridSize;
Params.MonitorDistance = MonitorDistance;
Params.MonitorResolution = MonRes;

% RF position
if exist('Xposition','var') && exist('Yposition','var')
    RFposition = [Xposition,Yposition];
elseif ~exist('RFposition','var')
    RFposition = [0,0];
end
Params.RFposition = RFposition;

% Stim Parameters
Params.StimDuration = StimDuration;
Params.StimInterval = StimInterval;

% Check for empty data matrices
if isempty(data)
    Params.Data = [];
    Params.nTrials = 0;
    disp(['no trials for ',FileName]);
    return
end

% Loading stim sequence
try
    StimSequence = LoadStimSequence(StimType, seqDir);
catch e
    disp(['Sequence not loaded for ',StimType]);
    StimSequence = [];
end

% Fix new sequences
SF = unique(data(:,3));
TF = unique(data(:,4));
Apt = unique(data(:,5));
if size(data,2) >= 7
    C = unique(data(:,7));
end
if strcmp(StimType,'MouseSpatial') && SF(1)<0.01
    load(fullfile(altSeqDir,'MouseSpatial_StimSequence'));
end
if strcmp(StimType,'MouseTemporal') ...
        && length(TF) ~= length(StimSequence(:,1,1))
    load(fullfile(altSeqDir,'MouseTemporal_StimSequence'));
end
if strcmp(StimType,'Contrast') && C(1) == 0
    load(fullfile(altSeqDir,'Contrast_StimSequence'));
end
if strcmp(StimType,'MouseAperture') && Apt(2) == 2
    load(fullfile(altSeqDir,'MouseAperture_StimSequence'));
end
if strcmp(StimType,'MouseAperture') && Apt(2) == 3
    load(fullfile(altSeqDir,'MouseAperture2_StimSequence'));
end

% Fill out Data table
Data = table;
switch StimType
    case {'Velocity', 'VelocityConstantCycles', ...
            'VelocityConstantCyclesBar'}
        Data.StimNo = data(:,1);
        Data.StimTime = data(:,2);
        Data.Velocity = data(:,3);
        Data.nDots = data(:,4);
        Data.Aperture = data(:,5);
        Data.Ori = data(:,6);
        Data.Contrast = data(:,7);
        Data.StimDuration = data(:,8);
        Data.TrialNo = data(:,9);
        Data.ConditionNo = data(:,10);
    case 'Looming'
        Data.StimNo = data(:,1);
        Data.StimTime = data(:,2);
        Data.Velocity = data(:,3);
        Data.Contrast = data(:,4);
        Data.StimDuration = data(:,5);
        Data.TrialNo = data(:,6);
        Data.ConditionNo = data(:,7);
        Data.Condition = data(:,3);
    case 'LatencyTest'
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.StimDuration = data(:,2);
        Data.TrialNo = data(:,3);
        Data.StimOffTime = data(:,4);
        Data.StimInterval = data(:,5);
        Data.ConditionNo = ones(size(data,1),1);
        StimSequence = ones(1,2,size(data,1));
    case 'LaserGratings'
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.StimDuration = data(:,2);
        Data.ISI = data(:,3);
        Data.TrialNo = data(:,4);
        Data.ConditionNo = data(:,5);
        StimSequence = ones(1,2,size(data,1));
    case 'LaserON'
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.StimDuration = data(:,2);
        Data.StimInterval = data(:,3);
        Data.TrialNo = data(:,4);
        Data.ConditionNo = ones(size(data,1),1);
        StimSequence = ones(1,2,size(data,1));
    case 'PatternMotion'
        Data.StimTime = data(:,1);
        Data.StimNo = (1:size(data,1))';
        Data.SF = data(:,3);
        Data.TF = data(:,4);
        Data.Aperture = data(:,5);
        Data.Ori = data(:,6);
        Data.Contrast = data(:,7);
        Data.StimDuration = data(:,8);
        Data.TrialNo = data(:,9);
        Data.Velocity = data(:,10);
        Data.ConditionNo = data(:,11);
    case 'RFmap'
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.ConditionNo = data(:,2);
        Data.XPosition = data(:,3);
        Data.YPosition = data(:,4);
        Data.Aperture = data(:,5);
    case 'CatRFdetailed'
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.ConditionNo = data(:,2);
        Data.Color = data(:,3);
        Data.XPosition = data(:,4);
        Data.YPosition = data(:,5);
        Data.Condition = [Data.XPosition Data.YPosition];
    case {'CatRFfast','CatRFfast10x10'}
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.ConditionNo = data(:,2);
        Data.Color = data(:,3);
        Data.XPosition = data(:,4);
        Data.YPosition = data(:,5);
        Data.StimDuration = data(:,6);
        Data.TrialNo = data(:,7);
        Data.SF = data(:,8);
        Data.TF = data(:,9);
        Data.Ori = data(:,10);
        Data.RFposition = data(:,11);
        Data.Condition = [Data.XPosition Data.YPosition];
    case {'NaturalImages', 'NaturalVideos'}
        Data.StimNo = (1:size(data,1))';
        Data.StimTime = data(:,1);
        Data.ConditionNo = data(:,2);
        Data.Condition = Data.ConditionNo;
        Data.StimDuration = data(:,4);
        Data.StimInterval = data(:,5);
        Data.TrialNo = data(:,6);
    otherwise
        if isempty(StimSequence)
            warning(['Unsupported filetype. Skipping ', FileName]);
            return;
        end
        Params.nConds = length(unique(StimSequence(:,1)));
        Params.nTrials = ceil(size(data,1)/Params.nConds);
        CondNo = reshape(StimSequence(1:Params.nConds,1,1:Params.nTrials),...
            Params.nConds*Params.nTrials,1);
        Data.ConditionNo = CondNo(1:size(data,1));
        
        % condition, StimTime, sf, tf, apt, ori, c, dur
        if size(data,2) >= 8
            Data.StimNo = (1:size(data,1))';
            Data.StimTime = data(:,2);
            Data.SF = data(:,3);
            Data.TF = data(:,4);
            Data.Aperture = data(:,5);
            Data.Ori = data(:,6);
            Data.Contrast = data(:,7);
            Data.StimDuration = data(:,8);
        else
            warning(['Unsupported log matrix. Skipping ', FileName]);
            return;
        end
        
        % trial no
        if size(data,2) >= 9
            Data.TrialNo = data(:,9);
        else
            Data.TrialNo = NaN(1:size(data,1));
        end
        
        % velocity
        if size(data,2) >= 10
            Data.Velocity = data(:,10);
        else
            Data.Velocity = data(:,4)./data(:,3);
        end
end

Params.nConds = length(unique(Data.ConditionNo));
Params.nTrials = floor(size(data,1)/Params.nConds);


% Transfer StimSequence to Data.Condition and Data.ConditionNo
if ~isempty(StimSequence)
    StimSequence = StimSequence(:,:,1:ceil(size(data,1)/Params.nConds));
end
Params.StimSequence = StimSequence;
Stim = num2cell(StimSequence, [1 2]);
Stim = vertcat(Stim{:}); % condition number, condition
if ~ismember('Condition', Data.Properties.VariableNames) || ...
        isempty(Data.Condition)
    Data.Condition = Stim(1:size(data,1),2);
end
if ~ismember('ConditionNo', Data.Properties.VariableNames) || ...
        isempty(Data.ConditionNo)
    Data.ConditionNo = Stim(1:size(data,1),1);
end
if ~ismember('StimInterval', Data.Properties.VariableNames) || ...
        isempty(Data.StimInterval)
    Data.StimInterval = StimInterval*ones(size(data,1),1);
end

% Data goes into params, too
Params.Data = Data;
end
