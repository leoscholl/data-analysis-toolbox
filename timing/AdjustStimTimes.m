function [stimTimesCorrected, stimOffTimesCorrected, source, ...
    latency, variation] = adjustStimTimes( Params, Events )
%AdjustStimTimes Adjust stim times to pick the most accurate ones

animalID = Params.AnimalID;
unitNo = Params.UnitNo;

stimsExist = isfield(Events, 'StimTimes');
if ~stimsExist || ~isfield(Events.StimTimes, 'photodiode') 
    stimTimesPhotodiode = []; 
else
    stimTimesPhotodiode = Events.StimTimes.photodiode;
end
if ~stimsExist || ~isfield(Events.StimTimes, 'parallel')
    stimTimesParallel = []; 
else
    stimTimesParallel = Events.StimTimes.parallel;
end

stimTimesCorrected = [];
stimOffTimesCorrected = [];
source = '';

% Collect times from params structure
stimTimesPTB = []; stimOffTimesPTB = []; 
startTimeRipple = []; endTimeRipple = [];
startTimePTB = []; endTimePTB = [];
if ismember('StimTime', Params.Data.Properties.VariableNames)
    stimTimesPTB = Params.Data.StimTime;
end
if ismember('StimOffTime', Params.Data.Properties.VariableNames)
    stimOffTimesPTB = Params.Data.StimOffTime; 
else
    stimOffTimesPTB = Params.Data.StimTime + Params.Data.StimDuration;
end

% Collect start and end times if they exist
startTimeRipple = -Inf;
endTimeRipple = Inf;
if isfield(Params, 'startTimeRipple'); startTimeRipple = Params.StartTimeRipple; end
if isfield(Params, 'endTimeRipple'); endTimeRipple = Params.EndTimeRipple; end
if isfield(Events, 'startTime') && ~isempty(Events.startTime)
    startTimeRipple = Events.startTime; 
end
if isfield(Events, 'endTime') && ~isempty(Events.endTime) 
    endTimeRipple = Events.endTime; 
end

% Replace old 'toc' StimTimes with 'GetSecs' PTB StimTimes if they exist
if ismember('StimOffTimePTB', Params.Data.Properties.VariableNames) && ...
    ismember('StimTimePTB', Params.Data.Properties.VariableNames) && ...
    isfield(Params, startTimePTB) && isfield(Params, endTimePTB)
    stimOffTimesPTB = Params.Data.StimOffTimePTB - Params.StartTimePTB; 
    stimTimesPTB = Params.Data.StimTimePTB - Params.StartTimePTB;
    startTimePTB = Params.StartTimePTB;
    endTimePTB = Params.EndTimePTB;
end

% StimTimesPTB always has the correct number of stims
if ~isempty(stimTimesPTB)
    nStims = length(stimTimesPTB);
else
    error('No stim times in data file');
end

% Adjust old param stim times
stimTimesLegacy = [];
stimOffTimesLegacy = [];
if strcmp(animalID(1),'R')
    if strcmp(animalID,'R1513') && unitNo <= 3
        stimTimesLegacy = stimTimesPTB+0.024;
    elseif strcmp(animalID,'R1508') || strcmp(animalID,'R1510') ...
            || strcmp(animalID,'R1511') || strcmp(animalID,'R1512')
        stimTimesLegacy = stimTimesPTB+0.024;
    else
        stimTimesLegacy = stimTimesPTB+0.141;
        stimOffTimesLegacy = stimOffTimesPTB+0.141;
    end
else
    % For old cat experiments, assume the CRT was fast enough that the
    % recorded stim times are accurate
    stimTimesLegacy = stimTimesPTB;
    stimOffTimesLegacy = stimOffTimesPTB;
end

% Make sure Parallel Stim times are ok
stimTimesParallelCorrected = [];
stimOffTimesParallelCorrected = [];
if ~isempty(stimTimesParallel)
    stimTimes = stimTimesParallel(1:2:end); % assume it always catches pairs?
    stimOffTimes = stimTimesParallel(2:2:end);
    stimTimes = reshape(stimTimes, length(stimTimes), 1);
    stimOffTimes = reshape(stimOffTimes, length(stimOffTimes), 1);

    % Estimate timer drift
    stimTimesInterp = stimTimeInterpolate(nStims, stimTimes);
    if length(stimTimesInterp) == nStims
        difference = stimTimesInterp - stimTimesPTB;
        X = [ones(nStims,1) [1:nStims]'];
        drift = X\difference;
        correction = X*drift;
    
        % Correct PTB stim times
        stimTimesPTB = stimTimesPTB + correction;
        stimOffTimesPTB = stimOffTimesPTB + correction;

    else
        fprintf('Could not correct PTB stim times for timer drift\n');
    end
    
    % Some sanity checks
    if length(stimTimes) ~= nStims || length(stimOffTimes) ~= nStims
        fprintf(2, 'Parallel port caught %d out of %d StimTimes\n', ...
            length(stimTimes) + length(stimOffTimes), nStims*2);
    elseif min(stimTimes) + 0.5 < min(stimTimesPTB) || ...
        (~isempty(stimTimesPhotodiode) && ...
        min(stimTimes) + 0.5 < min(stimTimesPhotodiode))
        fprintf(2, 'StimTimesParallel are too small.\n');
    elseif min(stimTimes) > 1000
        fprintf(2, 'StimTimesParallel are too big.\n');
    elseif sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.StimDuration + Params.Data.StimInterval)
        stimTimes = stimTimesLegacy;
        fprintf(2, 'At least one pair of StimTimesParallel are too close together.\n');
    elseif any(stimOffTimes - stimTimes + 0.1 < Params.Data.StimDuration)
        % on times ok, but off times are not
        fprintf(2, 'Parallel port stim off times are inaccurate\n');
        stimTimesParallelCorrected = stimTimes;
    else % everything ok
        stimTimesParallelCorrected = stimTimes;
        stimOffTimesParallelCorrected = stimOffTimes;
    end
    
end

latency = NaN;
variation = NaN;
if ~isempty(stimTimesPhotodiode)
    stimTimes = stimTimesPhotodiode(1:2:end); % assume it always catches pairs
    stimOffTimes = stimTimesPhotodiode(2:2:end);
    stimTimes = reshape(stimTimes, length(stimTimes), 1);
    stimOffTimes = reshape(stimOffTimes, length(stimOffTimes), 1);

    % Some sanity checks
    if length(stimTimes) ~= nStims || length(stimOffTimes) ~= nStims
        fprintf(2, 'Photodiode caught %d out of %d StimTimes\n', ...
            length(stimTimes) + length(stimOffTimes), nStims*2);
    elseif min(stimTimes) + 0.5 < min(stimTimesPTB) || ...
        (~isempty(stimTimesParallel) && ...
        min(stimTimes) + 0.5 < min(stimTimesParallel))
        fprintf(2, 'StimTimesPhotodiode are too small.\n');
    elseif min(stimTimes) > 1000
        fprintf(2, 'StimTimesPhotodiode are too big.\n');
    elseif sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.StimDuration + Params.Data.StimInterval)
        stimTimes = stimTimesLegacy;
        fprintf(2, 'At least one pair of StimTimesPhotodiode are too close together.\n');
    elseif any(stimOffTimes - stimTimes + 0.1 < Params.Data.StimDuration)
        % on times ok, but off times are not
        fprintf(2, 'photodiode stim off times are inaccurate\n');
        fprintf('using photodiode stim times\n');
        source = 'photodiode';
        stimTimesCorrected = stimTimes;
        stimOffTimesCorrected = stimTimes + Params.Data.StimDuration;
    else % everything ok
        fprintf('Using photodiode timestamps\n');
        source = 'photodiode';
        stimTimesCorrected = stimTimes;
        stimOffTimesCorrected = stimOffTimes;
    end

    % Calculate latency to the PTB stim times
    stimTimesInterp = stimTimeInterpolate(nStims, stimTimes);
    if length(stimTimesInterp) == nStims
        difference = stimTimesInterp - stimTimesPTB;
        latency = mean(difference);
        variation = std(difference);
    elseif strcmp(animalID(1),'R')
        fprintf('Could not correct timestamps with photodiode. Assuming 0.141 latency\n');
        latency = 0.141;
        variation = NaN;
    else
        fprintf('Could not correct timestamps with photodiode. Assuming 0 latency\n');
        latency = 0;
        variation = NaN;
    end
    
    % Correct other stim times
    if isempty(stimTimesCorrected) && ~isempty(stimTimesParallelCorrected) ...
            && ~isempty(stimOffTimesParallelCorrected)
        % Use parallel port times
        fprintf('Using parallel port timestamps (corrected with photodiode)\n');
        source = 'parallel';
        stimTimesCorrected = stimTimesParallelCorrected + latency;
        stimOffTimesCorrected = stimOffTimesParallelCorrected + latency;
    elseif isempty(stimTimesCorrected) && ~isempty(stimTimesParallelCorrected)
        % Use parallel on times, but PTB off times
        fprintf(['Using parallel port timestamps (corrected with photodiode)\n' ...
            '\tand parallel port + stim duration for off times\n']);
        source = 'parallel';
        stimTimesCorrected = stimTimesParallelCorrected + latency;
        stimOffTimesCorrected = stimTimesCorrected + Params.Data.StimDuration;
    elseif isempty(stimTimesCorrected)
        % Use PTB times
        fprintf('Using matlab timestamps (corrected with photodiode)\n');
        source = 'matlab';
        stimTimesCorrected = stimTimesPTB + latency;
        stimOffTimesCorrected = stimOffTimesPTB + latency;
    end
end

% Finally, check if there is a corrected stim time available
if isempty(stimTimesCorrected) && ~isempty(stimTimesLegacy)
    fprintf('Using matlab timestamps (corrected with 0.141)\n');
    source = 'matlab';
    stimTimesCorrected = stimTimesLegacy;
    stimOffTimesCorrected = stimOffTimesLegacy;
end

% Some last-minute sanity checks for whichever times we picked
if stimTimesCorrected(1) < startTimeRipple || ...
        stimTimesCorrected(end) > endTimeRipple || ...
        min(stimTimesCorrected) > 1000
    fprintf(2, 'StimTimes fall outside of the possible range. Aborting');
    stimTimesCorrected = [];
    stimOffTimesCorrected = [];
elseif sum([diff(stimTimesCorrected); NaN] + 0.1 < ...
        Params.Data.StimDuration + Params.Data.StimInterval)    
    fprintf(2, 'At least one pair of triggers are too close together.\n');
    stimTimesCorrected = [];
    stimOffTimesCorrected = [];
end

end

