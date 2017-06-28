function [ Electrodes, LFP, AnalogIn, Events ] = convertDataset( dataset )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
Electrodes = [];
LFP = [];
AnalogIn = [];
Events = [];

spikes = cellfun(@(x, y)[x' double(y)'], {dataset.spike.time}, {dataset.spike.unitid}, ...
    'UniformOutput', false)';
waveforms = cellfun(@(x, y, z)[x' double(y)' z'], {dataset.spike.time}, ...
    {dataset.spike.unitid}, {dataset.spike.data}, 'UniformOutput', false)';
name = cellfun(@(x)sprintf('elec %d', x), {dataset.spike.electrodeid}, 'UniformOutput', false)';
number = cell2mat({dataset.spike.electrodeid}');
Electrodes = table(spikes, waveforms, name, number);

LFP.endTime = dataset.lfp.time(2);
LFP.samplerate = dataset.lfp.fs;
name = arrayfun(@(x)sprintf('lfp %d', x), dataset.lfp.electrodeid, 'UniformOutput', false)';
number = dataset.lfp.electrodeid';
data = mat2cell(dataset.lfp.data, size(dataset.lfp.data,1), ones(1, size(dataset.lfp.data,2)))';
LFP.Channels = table(data, name, number);

AnalogIn.endTime = dataset.analog1k.time(2);
AnalogIn.samplerate = dataset.analog1k.fs;
name = arrayfun(@(x)sprintf('analog %d', x), dataset.analog1k.electrodeid, 'UniformOutput', false)';
number = dataset.analog1k.electrodeid';
data = mat2cell(dataset.analog1k.data, size(dataset.analog1k.data,1), ones(1, size(dataset.analog1k.data,2)))';
AnalogIn.Channels = table(data, name, number);

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
