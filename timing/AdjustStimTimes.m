function [StimTimesCorrected, StimOffTimesCorrected, Latency, Variation] = ...
    AdjustStimTimes( Params, StimTimesPhotodiode, StimTimesParallel)
%AdjustStimTimes Adjust stim times to pick the most accurate ones

AnimalID = Params.AnimalID;
UnitNo = Params.UnitNo;

StimTimesCorrected = [];
StimOffTimesCorrected = [];

% Collect times from params structure
StimTimesPTB = []; StimOffTimesPTB = []; 
StartTimeRipple = []; EndTimeRipple = [];
StartTimePTB = []; EndTimePTB = [];
if ismember('StimTime', Params.Data.Properties.VariableNames)
    StimTimesPTB = Params.Data.StimTime;
end
if ismember('StimOffTime', Params.Data.Properties.VariableNames)
    StimOffTimesPTB = Params.Data.StimOffTime; 
end
if isfield(Params, StartTimeRipple); StartTimeRipple = Params.StartTimeRipple; end
if isfield(Params, EndTimeRipple); EndTimeRipple = Params.EndTimeRipple; end

% Replace old 'toc' StimTimes with 'GetSecs' PTB StimTimes if they exist
if ismember('StimOffTimePTB', Params.Data.Properties.VariableNames) && ...
    ismember('StimTimePTB', Params.Data.Properties.VariableNames) && ...
    isfield(Params, StartTimePTB) && isfield(Params, EndTimePTB)
    StimOffTimesPTB = Params.Data.StimOffTimePTB - Params.StartTimePTB; 
    StimTimesPTB = Params.Data.StimTimePTB - Params.StartTimePTB;
    StartTimePTB = Params.StartTimePTB;
    EndTimePTB = Params.EndTimePTB;
end

% StimTimesPTB always has the correct number of stims
if ~isempty(StimTimesPTB)
    nStims = length(StimTimesPTB);
else
    error('No stim times in data file');
end

% Adjust old param stim times
StimOffTimesLegacy = [];
if strcmp(AnimalID(1),'R')
    if strcmp(AnimalID,'R1513') && UnitNo <= 3
        StimTimesLegacy = StimTimesPTB+0.024;
    elseif strcmp(AnimalID,'R1508') || strcmp(AnimalID,'R1510') ...
            || strcmp(AnimalID,'R1511') || strcmp(AnimalID,'R1512')
        StimTimesLegacy = StimTimesPTB+0.024;
    else
        StimTimesLegacy = StimTimesPTB+0.141;
        StimOffTimesLegacy = StimOffTimesPTB+0.141;
    end
else
    % For old cat experiments, assume the CRT was fast enough that the
    % recorded stim times are accurate
    StimTimesLegacy = StimTimesPTB;
    StimOffTimesLegacy = StimOffTimesPTB;
end

% Make sure Parallel Stim times are ok
StimTimesParallelCorrected = [];
StimOffTimesParallelCorrected = [];
if ~isempty(StimTimesParallel)
    StimTimes = StimTimesParallel(1:2:end); % assume it always catches pairs
    StimOffTimes = StimTimesParallel(2:2:end);
    StimTimes = reshape(StimTimes, length(StimTimes), 1);
    StimOffTimes = reshape(StimOffTimes, length(StimOffTimes), 1);

    % Estimate timer drift
    StimTimesInterp = StimTimeInterpolate(nStims, StimTimes);
    if length(StimTimesInterp) == nStims
        Difference = StimTimesInterp - StimTimesPTB;
        X = [ones(nStims,1) [1:nStims]'];
        Drift = X\Difference;
        Correction = X*Drift;
    
        % Correct PTB stim times
        StimTimesPTB = StimTimesPTB + Correction;
        if ~isempty(StimOffTimesPTB)
            StimOffTimesPTB = StimOffTimesPTB + Correction;
        end
    else
        fprintf('Could not correct PTB stim times for timer drift\n');
    end
    
    % Some sanity checks
    if length(StimTimes) ~= nStims || length(StimOffTimes) ~= nStims
        fprintf(2, 'Parallel port caught %d out of %d StimTimes\n', ...
            length(StimTimes) + length(StimOffTimes), nStims*2);
    elseif min(StimTimes) + 0.5 < min(StimTimesPTB) || ...
        (~isempty(StimTimesPhotodiode) && ...
        min(StimTimes) + 0.5 < min(StimTimesPhotodiode))
        fprintf(2, 'StimTimesParallel are too small.\n');
    elseif min(StimTimes) > 1000
        fprintf(2, 'StimTimesParallel are too big.\n');
    elseif sum([diff(StimTimes); NaN] + 0.1 < ...
            Params.Data.StimDuration + Params.Data.StimInterval)
        StimTimes = StimTimesLegacy;
        fprintf(2, 'At least one pair of StimTimesParallel are too close together.\n');
    else % everything ok
        StimTimesParallelCorrected = StimTimes;
        StimOffTimesParallelCorrected = StimOffTimes;
    end
    
end

if ~isempty(StimTimesPhotodiode)
    StimTimes = StimTimesPhotodiode(1:2:end); % assume it always catches pairs
    StimOffTimes = StimTimesPhotodiode(2:2:end);
    StimTimes = reshape(StimTimes, length(StimTimes), 1);
    StimOffTimes = reshape(StimOffTimes, length(StimOffTimes), 1);

    % Some sanity checks
    if length(StimTimes) ~= nStims || length(StimOffTimes) ~= nStims
        fprintf(2, 'Photodiode caught %d out of %d StimTimes\n', ...
            length(StimTimes) + length(StimOffTimes), nStims*2);
    elseif min(StimTimes) + 0.5 < min(StimTimesPTB) || ...
        (~isempty(StimTimesParallel) && ...
        min(StimTimes) + 0.5 < min(StimTimesParallel))
        fprintf(2, 'StimTimesPhotodiode are too small.\n');
    elseif min(StimTimes) > 1000
        fprintf(2, 'StimTimesPhotodiode are too big.\n');
    elseif sum([diff(StimTimes); NaN] + 0.1 < ...
            Params.Data.StimDuration + Params.Data.StimInterval)
        StimTimes = StimTimesLegacy;
        fprintf(2, 'At least one pair of StimTimesPhotodiode are too close together.\n');
    else % everything ok
        fprintf('Using photodiode timestamps\n');
        StimTimesCorrected = StimTimes;
        StimOffTimesCorrected = StimOffTimes;
    end

    % Calculate latency to the PTB stim times
    StimTimesInterp = StimTimeInterpolate(nStims, StimTimes);
    if length(StimTimesInterp) == nStims
        Difference = StimTimesInterp - StimTimesPTB;
        Latency = mean(Difference);
        Variation = std(Difference);
    elseif strcmp(AnimalID(1),'R')
        fprintf('Could not correct timestamps with photodiode. Assuming 0.141 latency\n');
        Latency = 0.141;
        Variation = NaN;
    else
        fprintf('Could not correct timestamps with photodiode. Assuming 0 latency\n');
        Latency = 0;
        Variation = NaN;
    end
    
    % Correct other stim times
    if isempty(StimTimesCorrected) && ~isempty(StimTimesParallelCorrected) ...
            && ~isempty(StimOffTimesParallelCorrected)
        % Use parallel port times
        fprintf('Using parallel port timestamps (corrected with photodiode)\n');
        StimTimesCorrected = StimTimesParallelCorrected + Latency;
        StimOffTimesCorrected = StimOffTimesParallelCorrected + Latency;
    elseif isempty(StimTimesCorrected)
        % Use PTB times
        fprintf('Using matlab timestamps (corrected with photodiode)\n');
        StimTimesCorrected = StimTimesPTB + Latency;
        if ~isempty(StimOffTimesPTB)
            StimOffTimesCorrected = StimOffTimesPTB + Latency;
        end
    end
end
    
% Finally, check if there is a corrected stim time available
if isempty(StimTimesCorrected)
    fprintf('Using matlab timestamps (corrected with 0.141)\n');
    StimTimesCorrected = StimTimesLegacy;
    StimOffTimesCorrected = StimOffTimesLegacy;
end

end

