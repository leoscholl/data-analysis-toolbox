function [stimTimesCorrected, stimOffTimesCorrected, source, ...
    latency, variation, hasError, msg] = adjustStimTimes( Params, Events )
%AdjustStimTimes Adjust stim times to pick the most accurate ones

animalID = Params.animalID;
unitNo = Params.unitNo;

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
msg = '';

% Collect times from params structure
stimTimesPTB = []; stimOffTimesPTB = []; 
startTimePTB = []; endTimePTB = [];
if ismember('stimTime', Params.Data.Properties.VariableNames)
    stimTimesPTB = Params.Data.stimTime;
end
if ismember('stimOffTime', Params.Data.Properties.VariableNames)
    stimOffTimesPTB = Params.Data.stimOffTime; 
else
    stimOffTimesPTB = Params.Data.stimTime + Params.Data.stimDuration;
end

% Collect start and end times if they exist
startTimeRipple = -Inf;
endTimeRipple = Inf;
if isfield(Params, 'startTimeRipple'); startTimeRipple = Params.startTimeRipple; end
if isfield(Params, 'endTimeRipple'); endTimeRipple = Params.endTimeRipple; end
if isfield(Events, 'startTime') && ~isempty(Events.startTime)
    startTimeRipple = Events.startTime; 
end
if isfield(Events, 'endTime') && ~isempty(Events.endTime) 
    endTimeRipple = Events.endTime; 
end

% Replace old 'toc' StimTimes with 'GetSecs' PTB StimTimes if they exist
if ismember('stimOffTimePTB', Params.Data.Properties.VariableNames) && ...
    ismember('stimTimePTB', Params.Data.Properties.VariableNames) && ...
    isfield(Params, startTimePTB) && isfield(Params, endTimePTB)
    stimOffTimesPTB = Params.Data.stimOffTimePTB - Params.startTimePTB; 
    stimTimesPTB = Params.Data.stimTimePTB - Params.startTimePTB;
    startTimePTB = Params.startTimePTB;
    endTimePTB = Params.endTimePTB;
end

% StimTimesPTB always has the correct number of stims
if ~isempty(stimTimesPTB)
    nStims = length(stimTimesPTB);
else
    error('No stim times in data file');
end

% Keep track of any errors
hasError = 0;

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
        msg = [msg, 'Could not correct PTB stim times for timer drift. '];
    end
    
    % Some sanity checks
    if length(stimTimes) ~= nStims || length(stimOffTimes) ~= nStims
        msg = [msg, sprintf('Parallel port caught %d out of %d StimTimes. ', ...
            length(stimTimes) + length(stimOffTimes), nStims*2)];
        hasError = 1;
    elseif min(stimTimes) + 0.5 < min(stimTimesPTB) || ...
        (~isempty(stimTimesPhotodiode) && ...
        min(stimTimes) + 0.5 < min(stimTimesPhotodiode))
        msg = [msg, 'StimTimesParallel are too small. '];
        hasError = 1;
    elseif min(stimTimes) > 1000
        msg = [msg, 'StimTimesParallel are too big. '];
        hasError = 1;
    elseif sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.stimDuration + Params.Data.stimInterval) && ...
            sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.stimDuration + Params.Data.stimInterval) < ...
            length(stimTimes)/2
        msg = [msg, 'At least one pair of StimTimesParallel are too close together. '];
        hasError = 1;
    elseif any(stimOffTimes - stimTimes + 0.1 < Params.Data.stimDuration)
        % on times ok, but off times are not
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
        msg = [msg, sprintf('Photodiode caught %d out of %d StimTimes. ', ...
            length(stimTimes) + length(stimOffTimes), nStims*2)];
        hasError = 1;
    elseif min(stimTimes) + 0.5 < min(stimTimesPTB) || ...
        (~isempty(stimTimesParallel) && ...
        min(stimTimes) + 0.5 < min(stimTimesParallel))
        msg = [msg, 'StimTimesPhotodiode are too small. '];
        hasError = 1;
    elseif min(stimTimes) > 1000
        msg = [msg, 'StimTimesPhotodiode are too big. '];
        hasError = 1;
    elseif sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.stimDuration + Params.Data.stimInterval) && ...
            sum([diff(stimTimes); NaN] + 0.1 < ...
            Params.Data.stimDuration + Params.Data.stimInterval) < ...
            length(stimTimes)/2
        stimTimes = stimTimesLegacy;
        msg = [msg, 'At least one pair of StimTimesPhotodiode are too close together. '];
        hasError = 1;
    elseif any(stimOffTimes - stimTimes + 0.1 < Params.Data.stimDuration)
        % on times ok, but off times are not
        msg = [msg, 'using photodiode stim times with stim duration for off times. '];
        source = 'photodiode';
        stimTimesCorrected = stimTimes;
        stimOffTimesCorrected = stimTimes + Params.Data.stimDuration;
    else % everything ok
        msg = [msg, 'Using photodiode timestamps. '];
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
        msg = [msg, 'Could not correct timestamps with photodiode. ', ...
            'Assuming 0.141 latency. '];
        latency = 0.141;
        variation = NaN;
    else
        msg = [msg, 'Could not correct timestamps with photodiode. ', ...
            'Assuming 0 latency. '];
        latency = 0;
        variation = NaN;
    end
    
    % Correct other stim times
    if isempty(stimTimesCorrected) && ~isempty(stimTimesParallelCorrected) ...
            && ~isempty(stimOffTimesParallelCorrected)
        % Use parallel port times
        msg = [msg, 'Using parallel port timestamps (corrected with photodiode). '];
        source = 'parallel';
        stimTimesCorrected = stimTimesParallelCorrected + latency;
        stimOffTimesCorrected = stimOffTimesParallelCorrected + latency;
    elseif isempty(stimTimesCorrected) && ~isempty(stimTimesParallelCorrected)
        % Use parallel on times, but PTB off times
        msg = [msg, 'Using parallel port timestamps (corrected with photodiode)', ...
            ' and parallel port + stim duration for off times. '];
        source = 'parallel';
        stimTimesCorrected = stimTimesParallelCorrected + latency;
        stimOffTimesCorrected = stimTimesCorrected + Params.Data.stimDuration;
    elseif isempty(stimTimesCorrected)
        % Use PTB times
        msg = [msg, 'Using matlab timestamps (corrected with photodiode). '];
        source = 'matlab';
        stimTimesCorrected = stimTimesPTB + latency;
        stimOffTimesCorrected = stimOffTimesPTB + latency;
    end
else
	% Older data, no photodiode. Use the parallel stim times if they are ok.
	if ~isempty(stimTimesParallelCorrected) && ...
		~isempty(stimOffTimesParallelCorrected)
		msg = [msg, 'Using uncorrected parallel port timestamps. '];
		source = 'parallel';
		stimTimesCorrected = stimTimesParallelCorrected;
        stimOffTimesCorrected = stimOffTimesParallelCorrected;
	elseif ~isempty(stimTimesParallelCorrected)
		msg = [msg, 'Using parallel port timestamps', ...
            ' and parallel port + stim duration for off times. '];
		source = 'parallel';
		stimTimesCorrected = stimTimesParallelCorrected;
        stimOffTimesCorrected = stimTimesParallelCorrected + Params.Data.stimDuration;
	end
end

% Finally, check if there is a corrected stim time available
if isempty(stimTimesCorrected) && ~isempty(stimTimesLegacy)
    msg = [msg, 'Using matlab timestamps (corrected with 0.141). '];
    source = 'matlab';
    stimTimesCorrected = stimTimesLegacy;
    stimOffTimesCorrected = stimOffTimesLegacy;
end

% Some last-minute sanity checks for whichever times we picked
nOverlappingPairs = sum([diff(stimTimesCorrected); NaN] + 0.1 < ...
        Params.Data.stimDuration + Params.Data.stimInterval);
outsideRange = stimTimesCorrected(1) < startTimeRipple || ...
        stimTimesCorrected(end) > endTimeRipple || ...
        min(stimTimesCorrected) > 1000;
if outsideRange
    msg = [msg, 'StimTimes fall outside of the possible range. Aborting. '];
    hasError = 2;
elseif nOverlappingPairs && nOverlappingPairs < length(stimTimesCorrected)/2
    % Probably ok if ALL of the stim times are too small -- stim duration
    % might be wrong...
    msg = [msg, 'At least one pair of triggers are too close together. '];
    hasError = 2;
end

if hasError
    fprintf(2, [msg, '\n']);
else
    disp(msg);
end

end

