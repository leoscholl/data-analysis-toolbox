function [ Events ] = loadDigitalEvents( dataset )
%loadDigitalEvents Loads digital TTL events from SMA 3, 4, and parallel in
%   Detailed explanation goes here

Events = [];
if isfield(dataset, 'digital')
    startTime = dataset.digital(cellfun(@(x)strcmp(x, 'SMA 3'),{dataset.digital.channel}'));
    if ~isempty(startTime)
        Events.startTime = startTime.time;
        if length(Events.startTime) > 1
            Events.startTime = max(Events.startTime);
        end
    else 
        Events.startTime = [];
    end    
    endTime = dataset.digital(cellfun(@(x)strcmp(x, 'SMA 4'),{dataset.digital.channel}'));
    if ~isempty(endTime)
        Events.endTime = endTime.time;
        if length(Events.endTime) > 1
            Events.endTime = min(Events.endTime);
        end
    end
    parallelInput = dataset.digital(cellfun(@(x)strcmp(x, 'Parallel Input'),{dataset.digital.channel}'));
    if ~isempty(parallelInput)
        Events.parallelInput = [parallelInput.time', parallelInput.data'];
    end
    photodiode = dataset.digital(cellfun(@(x)strcmp(x, 'SMA 2'),{dataset.digital.channel}'));
    if ~isempty(photodiode)
        Events.StimTimes.photodiode = photodiode.time;
    end
    parallel = dataset.digital(cellfun(@(x)strcmp(x, 'SMA 1'),{dataset.digital.channel}'));
    if ~isempty(parallel)
        Events.StimTimes.parallel = parallel.time;
    end
end

end

