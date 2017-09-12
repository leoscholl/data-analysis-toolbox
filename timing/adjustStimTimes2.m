function Events = adjustStimTimes2( Params, Events )
%AdjustStimTimes Adjust stim times to pick the most accurate ones

animalID = Params.animalID;
unitNo = Params.unitNo;

stimTimesPTB = [];
stimTimesPhotodiode = []; 
stimTimesParallel = []; 
hasError = 0; % keep track of any errors
msg = '';
source = '';
latency = 0;
variation = 0;

% Collect photodiode stim times if they exist
stimsExist = isfield(Events, 'StimTimes');
if stimsExist  && isfield(Events.StimTimes, 'photodiode') 
    nMarks = length(Events.StimTimes.photodiode);
    stimTimesPhotodiode = reshape(Events.StimTimes.photodiode, nMarks, 1);
end

% Collect parallel stim times if they exist
if stimsExist && isfield(Events.StimTimes, 'parallel')
    nMarks = length(Events.StimTimes.parallel);
    stimTimesParallel = reshape(Events.StimTimes.parallel, nMarks, 1);
end

% Collect PTB/matlab times from params structure
assert(ismember('stimTime', Params.Data.Properties.VariableNames));
nMarks = length(Params.Data.stimTime)*2;
stimTimesPTB = nan(nMarks, 1);
stimTimesPTB(1:2:nMarks-1) = Params.Data.stimTime;
if ismember('stimOffTime', Params.Data.Properties.VariableNames)
    stimTimesPTB(2:2:nMarks) = Params.Data.stimOffTime; 
else
    stimTimesPTB(2:2:nMarks) = Params.Data.stimTime + Params.Data.stimDuration;
end

% Collect start and end times if they exist
startTimeRipple = 0;
endTimeRipple = Inf;
startTimePTB = 0; 
endTimePTB = Inf;
if isfield(Params, 'startTimeRipple'); startTimeRipple = Params.startTimeRipple; end
if isfield(Params, 'endTimeRipple'); endTimeRipple = Params.endTimeRipple; end
if isfield(Events, 'startTime') && ~isempty(Events.startTime)
    startTimeRipple = Events.startTime; 
end
if isfield(Events, 'endTime') && ~isempty(Events.endTime) 
    endTimeRipple = Events.endTime; 
end
if ismember('stimOffTimePTB', Params.Data.Properties.VariableNames) && ...
    ismember('stimTimePTB', Params.Data.Properties.VariableNames) && ...
    isfield(Params, startTimePTB) && isfield(Params, endTimePTB)
    startTimePTB = Params.startTimePTB;
    endTimePTB = Params.endTimePTB;
end

% Update PTB's times with the new start times
stimTimesPTB = stimTimesPTB - startTimePTB + startTimeRipple;
    
% Fix if broken
rippleFirst = min(min(stimTimesParallel), min(stimTimesPhotodiode));
if rippleFirst > min(stimTimesPTB(:,1)) + 1
    % Not lined up within 1 second usually means the start time is wrong
    stimTimesPTB = stimTimesPTB + rippleFirst - min(stimTimesPTB);
end

Events.StimTimes.matlab = stimTimesPTB;
source = 'matlab';

% Switch PTB times with parallel times if available
stimTimesPass1 = stimTimesPTB;
if ~isempty(stimTimesParallel)
    
    offFactor = 0.5;
    [stimTimesPass1, parallelError] = ...
        correctTimes(stimTimesPass1, stimTimesParallel, offFactor);
    
    % Some experiments only have on times, others have both
    [~,p] = ttest(stimTimesPass1(2:2:end) - stimTimesPass1(1:2:end), ...
        stimTimesPTB(2:2:end) - stimTimesPTB(1:2:end));
    if p < 0.001
        stimTimesPass1(2:2:end) = stimTimesPass1(1:2:end) + ...
            stimTimesPTB(2:2:end) - stimTimesPTB(1:2:end);
    end

    % Make corrections for timer drift
    if parallelError < size(stimTimesPTB,1)/2
    
        difference = stimTimesPass1 - stimTimesPTB;
        X = [ones(nMarks,1) [1:nMarks]'];
        drift = X\difference;
        correction = X*drift;

        % Correct PTB stim times
        stimTimesPTB = stimTimesPTB + correction;
        Events.StimTimes.matlab = stimTimesPTB;

        % Do the switching again
        [stimTimesPass1, parallelError] = ...
            correctTimes(stimTimesPTB, stimTimesParallel, offFactor);
    end
    
    % Some experiments only have on times, others have both
    [~,p] = ttest(stimTimesPass1(2:2:end) - stimTimesPass1(1:2:end), ...
        stimTimesPTB(2:2:end) - stimTimesPTB(1:2:end));
    if p < 0.001
        stimTimesPass1(2:2:end) = stimTimesPass1(1:2:end) + ...
            stimTimesPTB(2:2:end) - stimTimesPTB(1:2:end);
        parallelError(2:2:end) = true;
    end
    
    % Calculate real latency
    difference = stimTimesPass1 - stimTimesPTB;
    variation = std(difference);
    
    % Correct if the variation is low enough
    if variation > 0.03 % should be ifi... don't have that info
        msg = sprintf(['%sParallel introduced too much variation (%0.1fms). ', ...
            'Reverting to PTB times. '], msg, variation*1000);
        hasError = hasError + 1;
        stimTimesPass1 = stimTimesPTB;
    else
        source = 'parallel';
    end
    
    if any(parallelError)
        msg = sprintf('Parallel port missed %d/%d triggers. ', sum(parallelError), nMarks);
    end
    hasError = hasError + (length(stimTimesParallel) ~= length(stimTimesPTB)); 

else
    msg = [msg, 'No parallel port triggers. '];
end

% Adjust these stim times to be more or less accurate based on average
% latency of the monitors used
if strcmp(animalID(1),'R')
    if strcmp(animalID,'R1513') && unitNo <= 3
        latency = 0.024; % samsung
    elseif strcmp(animalID, 'R1504') || strcmp(animalID,'R1506') || ...
            strcmp(animalID,'R1508') || strcmp(animalID,'R1510') ...
            || strcmp(animalID,'R1511') || strcmp(animalID,'R1512')
        latency = 0.024;
    else
        latency = 0.141; % RCA tv
    end
else
    latency = 0; % CRT
end

% Now update with photodiode, if available
stimTimesPass2 = stimTimesPass1 + latency;
if ~isempty(stimTimesPhotodiode)
    
    offFactor = 0.5;
    [stimTimesPass2, photoError] = ...
        correctTimes(stimTimesPass2, stimTimesPhotodiode, offFactor);
    
    % Some experiments only have on times, others have both
    [~,p] = ttest(stimTimesPass2(2:2:end) - stimTimesPass2(1:2:end), ...
        stimTimesPTB(2:2:end) - stimTimesPTB(1:2:end));
    if p < 0.001
        stimTimesPass2(2:2:end) = stimTimesPass2(1:2:end) + ...
            stimTimesPass1(2:2:end) - stimTimesPass1(1:2:end);
        photoError(2:2:end) = true;
    end
    
    % Calculate real latency
    difference = stimTimesPass2 - stimTimesPTB;
    variation = std(difference);
    
    % Correct if the variation is low enough
    if variation < 0.03 % should be ifi... don't have that info
        latency = mean(difference);
        stimTimesPass2(photoError) = stimTimesPass1(photoError) + latency;
        source = 'photodiode';
    else
        msg = sprintf(['%sPhotodiode introduced too much variation (%0.1fms). ', ...
            'Reverting. '], msg, variation*1000);
        hasError = hasError + 1;
        stimTimesPass2 = stimTimesPass1 + latency;
    end
    
    if any(photoError)
        msg = sprintf('%sPhotodiode missed %d/%d triggers. ', msg, sum(photoError), nMarks);
    end
    hasError = hasError + (length(stimTimesPhotodiode) ~= length(stimTimesPTB));
else
    msg = [msg, 'No photodiode triggers. '];
end

difference = stimTimesPass2 - stimTimesPTB;
latency = mean(difference);
variation = std(difference);

msg = sprintf('%sLatency is %0.0f +/- %0.1fms', msg, latency*1000, variation*1000);

Events.StimTimes.on = stimTimesPass2(1:2:end);
Events.StimTimes.off = stimTimesPass2(2:2:end);
Events.StimTimes.latency = latency;
Events.StimTimes.variation = variation;
Events.StimTimes.source = source;
Events.StimTimes.hasError = hasError;
Events.StimTimes.msg = msg;

end


function [corrected, error] = correctTimes(reference, new, offFactor)

corrected = reference;

stimDiffTime = diff(reference);
stimDiffTimePlus = [stimDiffTime; max(stimDiffTime)].*offFactor;
stimDiffTimeMinus = [max(stimDiffTime); diff(reference)].*offFactor;

error = false(size(corrected,1),1);
i = 1; window = 3;
for t = 1:size(reference,1)
    if i > size(new,1)
        error(t) = true;
        continue;
    end
    j = 0;
    found = 0;
    while ~found && j < window
        if i+j <= size(new,1) && ...
                new(i+j) < reference(t) + stimDiffTimePlus(t) && ...
                new(i+j) > reference(t) - stimDiffTimeMinus(t)
            corrected(t) = new(i+j);
            found = 1;
        end
        j = j + 1;
    end
    if ~found
        error(t) = true;
    else
        i = i + j;
    end
end
end
