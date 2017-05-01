function [SpikeTimesAll, StimTimes, WaveformsAll, ElectrodeNames, ...
    StimType, Params, StimSequence, LFPDataAll, LFPEndTime, LFPSampleRate] ...
    = LoadExperiment(DataDir, AnimalID, Unit, FileName, FileType)

if nargin < 5 || isempty(FileType)
    FileType = 'unsorted';
end

[~, FileName, ~] = fileparts(FileName);
[~, FileNo, ~] = ParseFile(FileName);
UnitNo = str2num(Unit(5:end));
DataPath = fullfile(DataDir, AnimalID, Unit, filesep);

%% Load export file
if exist([DataPath,FileName,'-export.mat'],'file')
    load([DataPath,FileName,'-export.mat']);
end

% Check spikes
switch FileType
    case 'unsorted'
        if ~(exist('SpikeTimesAll_Ripple', 'var') && ...
                exist('WaveformsAll_Ripple', 'var') && ...
                exist('ElectrodeNames_Ripple', 'var') && ...
                exist('StimTimesParallel', 'var') && ...
                exist('StimTimesPhotodiode', 'var'))
            % Attempt to convert from ripple
            ConvertRippleSpikes(DataDir, AnimalID, UnitNo, FileNo);
            load([DataPath,FileName,'-export.mat']);
        end
        SpikeTimesAll = SpikeTimesAll_Ripple;
        WaveformsAll = WaveformsAll_Ripple;
        ElectrodeNames = ElectrodeNames_Ripple;
        
    case 'osort'
        SpikeTimesAll = SpikeTimesAll_OSort;
        WaveformsAll = WaveformsAll_OSort;
        ElectrodeNames = ElectrodeNames_OSort;
        
    case 'plexon'
        SpikeTimesAll = SpikeTimesAll_Plexon;
        WaveformsAll = WaveformsAll_Plexon;
        ElectrodeNames = ElectrodeNames_Plexon;
    otherwise
        error('Unsupported filetype');
end

% Check params
if ~exist('Params', 'var') 
    ConvertLogMats(DataDir, AnimalID, UnitNo, FileNo);
    load([DataPath,FileName,'-export.mat']);
    if ~exist('Params', 'var')
        error(['Missing Params for ', FileName]);
    end
end

% Pull out StimType and StimSequence
StimType = Params.StimType;
if isfield(Params,'StimSequence')
    StimSequence = Params.StimSequence;
else
    StimSequence = [];
end

% Check LFP
if ~exist('LFPDataAll', 'var') || ~exist('LFPEndTime', 'var') ...
        || ~exist('LFPSampleRate', 'var') ...
        || ~exist('LFPElectrodeNames', 'var')
    % Attempt to convert from ripple
    ConvertRippleLFP(DataDir, AnimalID, UnitNo, FileNo);
    load([DataPath,FileName,'-export.mat']);
end

% Check StimTimes
if ~exist('StimTimesPhotodiode', 'var'); StimTimesPhotodiode = []; end
if ~exist('StimTimesParallel', 'var'); StimTimesPhotodiode = []; end

% Adjust StimTimes
Params.UnitNo = UnitNo;
StimTimes = AdjustStimTimes(Params, StimTimesPhotodiode, StimTimesParallel);

end