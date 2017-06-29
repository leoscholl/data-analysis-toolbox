function Params = convertLogMat( dataPath, fileName )
%ConvertLogMats Reads the log matrix from visstim and creates a new
%parameters file

% Location for alternate sequences
if ispc
    home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
else
    home = getenv('HOME');
end
if strcmp(getenv('COMPUTERNAME'), 'STUDENTLYONLAB')
    home = '\\STUDENTLYONLAB\Users\Andrzej\';
end
seqDir = fullfile(home,'Dropbox','TunningCurvePlugin');
altSeqDir = fullfile(home,'Dropbox','TunningCurvePlugin','NewSeq');
addpath(seqDir);

Params = [];

filePath = fullfile(dataPath, [fileName, '.mat']);
if ~exist(filePath, 'file')
    warning('Cannot convert empty file');
    return;
end

fileVars = who('-file', filePath);
vars = {'data','GridSize',...
    'MonitorDistance','MonRes','MonSize','RFposition'};
if ismember('PPD',fileVars)
    vars{end+1} = 'PPD';
end
if ismember('StimInterval',fileVars)
    vars{end+1} = 'StimInterval';
end
if ismember('StimDuration',fileVars)
    vars{end+1} = 'StimDuration';
end
load(filePath, vars{:});
[animalID, expNo, stimType] = parseFileName(fileName);
Params.expNo = expNo;
Params.animalID = animalID;
Params.stimType = stimType;
pathParts = strsplit(dataPath,filesep);
Params.unit = char(pathParts{end});

% Monitor resolution, size, PPD, etc.
if exist('MonRes','var')
    monRes = cellfun(@str2num,regexp(MonRes,'\d+','match'));
else
    monRes = [1920 1080];
end
if exist('PPD', 'var')
    Params.ppd = PPD;
    Params.monitorSize = NaN;
elseif ischar(MonSize)
    Params.monitorSize = MonSize; % needs fixing
else
    Params.monitorSize = MonSize;
    Resolution.width = monRes(2);
    Resolution.height = monRes(1);
    Params.ppd = monitorPPD(Resolution, MonSize, MonitorDistance);
end
Params.gridSize = GridSize;
Params.monitorDistance = MonitorDistance;
Params.monitorResolution = monRes;

% RF position
if exist('RFposition','var')
    rfPosition = RFposition;
elseif exist('Xposition','var') && exist('Yposition','var')
    rfPosition = [Xposition,Yposition];
else
    rfPosition = [0,0];
end
Params.rfPosition = rfPosition;

% Stim Parameters
if exist('StimDuration', 'var')
    Params.stimDuration = StimDuration;
else
    Params.stimDuration = NaN;
end
if exist('StimInterval', 'var')
    Params.stimInterval = StimInterval;
else
    Params.stimInterval = NaN;
end

% Check for empty data matrices
if isempty(data)
    Params.Data = [];
    Params.nTrials = 0;
    disp(['no trials for ',FileName]);
    return
end

% Loading stim sequence
try
    stimSequence = LoadStimSequence(stimType, seqDir);
catch e
    warning(['Sequence not loaded for ',stimType]);
    stimSequence = [];
end

% Fix new sequences
sf = unique(data(:,3));
tf = unique(data(:,4));
if size(data,2) >= 5
    apt = unique(data(:,5));
end
if size(data,2) >= 7
    con = unique(data(:,7));
end
if strcmp(stimType,'MouseSpatial') && sf(1)<0.01
    load(fullfile(altSeqDir,'MouseSpatial_StimSequence'));
    stimSequence = StimSequence;
end
if strcmp(stimType,'MouseTemporal') ...
        && length(tf) ~= length(stimSequence(:,1,1))
    load(fullfile(altSeqDir,'MouseTemporal_StimSequence'));
    stimSequence = StimSequence;
end
if strcmp(stimType,'contrast') && con(1) == 0
    load(fullfile(altSeqDir,'Contrast_StimSequence'));
    stimSequence = StimSequence;
end
if strcmp(stimType,'MouseAperture') && apt(2) == 2
    load(fullfile(altSeqDir,'MouseAperture_StimSequence'));
    stimSequence = StimSequence;
end
if strcmp(stimType,'MouseAperture') && apt(2) == 3
    load(fullfile(altSeqDir,'MouseAperture2_StimSequence'));
    stimSequence = StimSequence;
end

% Fill out Data table
Data = table;
switch stimType
    case {'velocity', 'VelocityConstantCycles', ...
            'VelocityConstantCyclesBar'}
        Data.stimNo = data(:,1);
        Data.stimTime = data(:,2);
        Data.velocity = data(:,3);
        Data.nDots = data(:,4);
        Data.aperture = data(:,5);
        Data.ori = data(:,6);
        Data.contrast = data(:,7);
        Data.stimDuration = data(:,8);
        Data.trialNo = data(:,9);
        Data.conditionNo = data(:,10);
    case 'Looming'
        Data.stimNo = data(:,1);
        Data.stimTime = data(:,2);
        Data.velocity = data(:,3);
        Data.contrast = data(:,4);
        Data.stimDuration = data(:,5);
        Data.trialNo = data(:,6);
        Data.conditionNo = data(:,7);
        Data.condition = data(:,3);
    case 'LatencyTest'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.trialNo = data(:,3);
        Data.stimOffTime = data(:,4);
        Data.stimInterval = data(:,5);
        Data.conditionNo = ones(size(data,1),1);
        stimSequence = ones(1,2,size(data,1));
    case 'LaserGratings'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.isi = data(:,3);
        Data.trialNo = data(:,4);
        Data.conditionNo = data(:,5);
        stimSequence = ones(1,2,size(data,1));
    case 'LaserON'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.stimInterval = data(:,3);
        Data.trialNo = data(:,4);
        Data.conditionNo = ones(size(data,1),1);
        stimSequence = ones(1,2,size(data,1));
    case 'PatternMotion'
        Data.stimTime = data(:,1);
        Data.stimNo = (1:size(data,1))';
        Data.sf = data(:,3);
        Data.tf = data(:,4);
        Data.aperture = data(:,5);
        Data.ori = data(:,6);
        Data.contrast = data(:,7);
        Data.stimDuration = data(:,8);
        Data.trialNo = data(:,9);
        Data.velocity = data(:,10);
        Data.conditionNo = data(:,11);
    case 'RFmap'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.xPosition = data(:,3);
        Data.yPosition = data(:,4);
        Data.aperture = data(:,5);
        Data.condition = data(:,3:4);
        stimSequence = [];
    case 'CatRFdetailed'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.color = data(:,3);
        Data.xPosition = data(:,4);
        Data.yPosition = data(:,5);
        Data.condition = [Data.xPosition Data.yPosition];
    case {'CatRFfast10x10'}
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.color = data(:,3);
        Data.xPosition = data(:,4);
        Data.yPosition = data(:,5);
        Data.stimDuration = data(:,6);
        Data.trialNo = data(:,7);
        Data.sf = data(:,8);
        Data.tf = data(:,9);
        Data.ori = data(:,10);
        Data.rfPosition = data(:,11);
        Data.condition = [Data.xPosition Data.yPosition];
    case {'CatRFfast'} % 'CatRFfast' is broken, condition numbers are wrong
        warning(['Unsupported filetype. Skipping ', fileName]);
        return;
    case {'NaturalImages', 'NaturalVideos'}
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.condition = Data.conditionNo;
        Data.stimDuration = data(:,4);
        Data.stimInterval = data(:,5);
        Data.trialNo = data(:,6);
    otherwise
        if isempty(stimSequence)
            warning(['Unsupported filetype. Skipping ', fileName]);
            return;
        end
        Params.nConds = length(unique(stimSequence(:,1)));
        Params.nTrials = ceil(size(data,1)/Params.nConds);
        CondNo = reshape(stimSequence(1:Params.nConds,1,1:Params.nTrials),...
            Params.nConds*Params.nTrials,1);
        Data.conditionNo = CondNo(1:size(data,1));
        
        % condition, stimTime, sf, tf, apt, ori, c, dur
        if size(data,2) >= 8
            Data.stimNo = (1:size(data,1))';
            Data.stimTime = data(:,2);
            Data.sf = data(:,3);
            Data.tf = data(:,4);
            Data.aperture = data(:,5);
            Data.ori = data(:,6);
            Data.contrast = data(:,7);
            Data.stimDuration = data(:,8);
        else
            warning(['Unsupported log matrix. Skipping ', fileName]);
            return;
        end
        
        % trial no
        if size(data,2) >= 9
            Data.trialNo = data(:,9);
        else
            Data.trialNo = NaN(1:size(data,1));
        end
        
        % velocity
        if size(data,2) >= 10
            Data.velocity = data(:,10);
        else
            Data.velocity = data(:,4)./data(:,3);
        end
end

Params.nConds = length(unique(Data.conditionNo));
Params.nTrials = floor(size(data,1)/Params.nConds);


% Transfer StimSequence to Data.condition and Data.conditionNo
if ~isempty(stimSequence)
    stimSequence = stimSequence(:,:,1:ceil(size(data,1)/Params.nConds));
end
Params.StimSequence = stimSequence;
stim = num2cell(stimSequence, [1 2]);
stim = vertcat(stim{:}); % condition number, condition
if ~ismember('condition', Data.Properties.VariableNames) || ...
        isempty(Data.condition)
    Data.condition = stim(1:size(data,1),2);
end
if ~ismember('conditionNo', Data.Properties.VariableNames) || ...
        isempty(Data.conditionNo)
    Data.conditionNo = stim(1:size(data,1),1);
end
if ~ismember('stimInterval', Data.Properties.VariableNames) || ...
        isempty(Data.stimInterval)
    Data.stimInterval = Params.stimInterval*ones(size(data,1),1);
end

% Data goes into params, too
Params.Data = Data;

rmpath(seqDir);
end
