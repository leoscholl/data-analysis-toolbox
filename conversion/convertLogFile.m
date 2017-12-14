function Params = convertLogFile( dataPath, fileName )
%ConvertLogMats Reads the log matrix from visstim and creates a new
%parameters file

Params = [];

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


% Locate the log file
dataPath = fullfile(dataPath, filesep);
filePath = fullfile(dataPath, [fileName, '.mat']);
pathParts = strsplit(dataPath, filesep);
if ~exist(filePath, 'file')
    warning('File does not exist (%s)', filePath);
    rmpath(seqDir);
    return;
end

% What to load?
all = load(filePath, '-regexp', '^(?!handles)^(?!hObject)\w');
fileVars = fieldnames(all);
vars = {'data','GridSize',...
    'MonitorDistance','MonRes','MonSize','RFposition',...
    'PPD', 'StimInterval', 'StimDuration', 'Params'};
vars = intersect(vars, fileVars);

Params = [];
load(filePath, vars{:});

% Fix any Params that have CamelCase naming
if ~isempty(Params)
    
    oldParams = Params;
    Params = [];
    fields = {{'AnimalID', 'animalID'}, {'Unit', 'unit'}, ...
        {'ExpNo', 'expNo'}, {'StimType', 'stimType'}, {'Ori', 'ori'}, ...
        {'SF', 'sf'}, {'C', 'contrast'}, {'PPD', 'ppd'}, ...
        {'StimDuration', 'stimDuration'}, ...
        {'RFposition', 'rfPosition'}, {'BarWidth', 'barWidth'},...
        {'BarLength', 'barLength'}, {'BarHeight', 'barLength'}, ...
        {'CircleSize', 'circleSize'}, ...
        {'BlankColorString', 'blankColorString'},...
        {'StimColorString', 'stimColorString'}, {'Aperture', 'aperture'},... 
        {'DrawMask', 'drawMask'}, {'SquareGratings', 'squareGratings'}, ...
        {'ScreenNumber', 'screenNumber'}, {'ScreenRect', 'screenRect'},...
        {'MonitorSize', 'monitorDiagonal'}, {'GridSize', 'gridSize'}, ...
        {'MonitorDistance', 'monitorDistance'}, ...
        {'MonitorResolution', 'monitorResolution'}, ...
        {'StimInterval', 'stimInterval'}, ...
        {'StimIntervalMax', 'stimIntervalMax'},...
        {'StimDuration', 'stimDuration'},...
        {'StartTimePTB', 'startTimePTB'}, {'EndTimePTB', 'endTimePTB'},...
        {'StartTimeRipple', 'startTimeRipple'},...
        {'EndTimeRipple', 'endTimeRipple'}, ...
        {'monitorSize', 'monitorDiagnoal'}, ...
        'nTrials', 'expNo', 'animalID', 'stimType', 'unit', ...
        'ppd', 'gridSize', 'monitorDistance', ...
        'monitorResolution', 'rfPosition', 'stimDuration', ...
        'stimInterval', 'stimInvervalMax', 'nConds', 'nTrials'};
    
    Params = copyStructFields(oldParams, Params, fields);
    
    Params.unit = char(pathParts{end-1});
    Params.unitNo = sscanf(Params.unit, 'Unit%d');

    % Some newer files have the Data table already filled out, but with
    % CamelCase property names

    if isfield(oldParams, 'Data') && ~isempty(oldParams.Data)
        columns = oldParams.Data.Properties.VariableNames;
        Params.Data = oldParams.Data;
        if ismember('CircleSize', columns) && length(columns) == 17
            Params.Data.Properties.VariableNames = {'conditionNo','stimTime',...
                'velocity','apterture','ori','contrast','stimDuration','trialNo',...
                'stimInterval','stimOffTime','stimTimePTB', 'stimOffTimePTB',...
                'condition', 'circleSize', 'barWidth', 'barLength', 'nObjects'};
        else
            Params.Data.Properties.VariableNames = {'conditionNo','stimTime','sf','tf',...
                'apterture','ori','contrast','stimDuration','trialNo','velocity',...
                'stimInterval','stimOffTime','stimTimePTB','stimOffTimePTB','condition'};
        end
        condName = {Params.stimType};
        Params = gatherConditions(Params, Params.Data, [], condName);

        rmpath(seqDir);
        return;
    end
end


% Start adding parameters
[animalID, expNo, stimType] = parseFileName(fileName);
Params.expNo = expNo;
Params.animalID = animalID;
Params.stimType = stimType;
Params.unit = char(pathParts{end-1});
Params.unitNo = sscanf(Params.unit, 'Unit%d');

% Monitor resolution, size, PPD, etc.
if exist('MonRes','var')
    Params.monitorResolution = sscanf(MonRes,'%f x %f');
else
    Params.monitorResolution = [NaN NaN];
end
if exist('MonitorDistance', 'var')
    Params.monitorDistance = MonitorDistance;
else
    Params.monitorDistance = NaN;
end
if exist('MonSize', 'var') && ischar(MonSize)
    Params.monitorDegrees = sscanf(MonSize,'%f x %f');
    ppd = mean(Params.monitorResolution ./ Params.monitorDegrees);
    ppi = ppd/(2*Params.monitorDistance*tand(0.5))*2.54; % convert to inches
    Params.monitorDiagonal = round(sqrt((Params.monitorResolution(1)^2+Params.monitorResolution(2)^2))/ppi);
elseif exist('MonSize', 'var')
    Params.monitorDiagonal = MonSize;
else
    Params.monitorDiagonal = NaN;
end
if exist('PPD', 'var')
    Params.ppd = PPD;
else
    Resolution.width = Params.monitorResolution(2);
    Resolution.height = Params.monitorResolution(1);
    Params.ppd = monitorPPD(Resolution, Params.monitorDiagonal, Params.monitorDistance);
end
if exist('GridSize', 'var')
    Params.gridSize = GridSize;
else
    Params.gridSize = NaN;
end

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
    disp(['no trials for ',fileName]);
    rmpath(seqDir);
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
condName = {};
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
        condName = {'Velocity'};
    case 'Looming'
        Data.stimNo = data(:,1);
        Data.stimTime = data(:,2);
        Data.velocity = data(:,3);
        Data.contrast = data(:,4);
        Data.stimDuration = data(:,5);
        Data.trialNo = data(:,6);
        Data.conditionNo = data(:,7);
        Data.condition = data(:,3);
        condName = {'Velocity'};
    case 'LatencyTest'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.trialNo = data(:,3);
        Data.stimOffTime = data(:,4);
        Data.stimInterval = data(:,5);
        Data.conditionNo = ones(size(data,1),1);
        stimSequence = ones(1,2,size(data,1));
        condName = {'Visible'};
    case 'LaserGratings'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.isi = data(:,3);
        Data.trialNo = data(:,4);
        Data.conditionNo = data(:,5);
        stimSequence = ones(1,2,size(data,1));
        condName = {'Visible'};
    case 'LaserON'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.stimDuration = data(:,2);
        Data.stimInterval = data(:,3);
        Data.trialNo = data(:,4);
        Data.conditionNo = ones(size(data,1),1);
        stimSequence = ones(1,2,size(data,1));
        condName = {'Laser'};
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
        condName = {'Orientation'};
    case 'RFmap'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.xPosition = data(:,3);
        Data.yPosition = data(:,4);
        Data.aperture = data(:,5);
        Data.condition = data(:,3:4);
        Params.stimDuration = 0.05;
        Params.stimInterval = 0.3;
        stimSequence = [];
        condName = {'X_Position', 'Y_Position'};
    case 'CatRFdetailed'
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.color = data(:,3);
        Data.xPosition = data(:,4);
        Data.yPosition = data(:,5);
        Data.condition = [Data.xPosition Data.yPosition];
        condName = {'X_Position', 'Y_Position'};
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
        condName = {'X_Position', 'Y_Position'};
    case {'CatRFfast'} % 'CatRFfast' is broken, condition numbers are wrong
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
%         Data.conditionNo = data(:,2);
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
        stimSequence = [];
        condName = {'xPosition', 'yPosition'};
    case {'NaturalImages', 'NaturalVideos'}
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.condition = Data.conditionNo;
        Data.stimDuration = data(:,4);
        Data.stimInterval = data(:,5);
        Data.trialNo = data(:,6);
        condName = {'Image'};
    case {'WholeScreenMapLP'}
        Data.stimNo = (1:size(data,1))';
        Data.stimTime = data(:,1);
        Data.conditionNo = data(:,2);
        Data.color = data(:,3);
        Data.xPosition = data(:,4);
        Data.yPosition = data(:,5);
        Data.stimDuration = data(:,6);
        Data.trialNo = data(:,7);
        Data.condition = [Data.xPosition Data.yPosition];
        condName = {'xPosition','yPosition'};
    otherwise
        if isempty(stimSequence)
            warning(['Unsupported filetype. Skipping ', fileName]);
            rmpath(seqDir);
            return;
        end
%         Params.nConds = length(unique(stimSequence(:,1)));
%         Params.nTrials = ceil(size(data,1)/Params.nConds);
%         conditionNo = reshape(stimSequence(1:Params.nConds,1,1:Params.nTrials),...
%             Params.nConds*Params.nTrials,1);
%         Data.conditionNo = conditionNo(1:size(data,1));
        
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
            rmpath(seqDir);
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
        
        % condition name
        if contains(stimType, 'Ori')
            condName = {'Orientation'};
        elseif contains(stimType, 'Spatial')
            condName = {'Spatial_Frequency'};
        elseif contains(stimType, 'Temporal')
            condName = {'Temporal_Frequency'};
        elseif contains(stimType, 'Contrast')
            condName = {'Contrast'};
        elseif contains(stimType, 'Aperture')
            condName = {'Aperture'};
        elseif contains(stimType, 'Velocity')
            condName = {'Velocity'};
        else
            condName = {stimType};
        end
end

if isempty(condName)
    condName = {stimType};
end

Params = gatherConditions(Params, Data, stimSequence, condName);

% Data goes into params, too
Params.nTrials = floor(size(data,1)/Params.nConds);

rmpath(seqDir);
end


% Helper to add Params.conditions
function Params = gatherConditions(Params, Data, stimSequence, condName)

stim = num2cell(stimSequence, [1 2]);
stim = vertcat(stim{:}); % condition number, condition
    
if ~ismember('condition', Data.Properties.VariableNames) || ...
        isempty(Data.condition)
    if ~isempty(stim)
        Data.condition = stim(1:size(Data,1),2);
    end
end

% Generate new condition numbers - old ones are sometimes wrong
conditions = unique(Data.condition,'rows');
conditions = reshape(conditions, length(conditions), size(Data.condition,2));
conditionNo = zeros(length(Data.condition),1);
for i = 1:length(Data.condition)
    conditionNo(i) = find(sum(Data.condition(i,:) == ...
        conditions,2) == size(Data.condition,2)); % should only be one!
end
Data.conditionNo = conditionNo;

Conditions = struct;
for i = 1:length(condName)
    Conditions.(condName{i}) = conditions(:,i);
end
Params.Conditions = Conditions;

if ~ismember('stimInterval', Data.Properties.VariableNames) || ...
        isempty(Data.stimInterval)
    Data.stimInterval = Params.stimInterval*ones(size(Data,1),1);
end
if ~ismember('stimDuration', Data.Properties.VariableNames) || ...
        isempty(Data.stimDuration)
    Data.stimDuration = Params.stimDuration*ones(size(Data,1),1);
end

Params.Data = Data;
Params.nConds = size(conditions,1);

assert(isfield(Params, 'Conditions') && ~isempty(Params.Conditions));
end
