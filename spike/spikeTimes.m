function [sub] = spikeTimes(spikes, t0, t1)
%SPIKETIMES returns sub-vector of times in given range for given unit
%   Detailed explanation goes here
sub = spikes(spikes > t0 & spikes <= t1);
sub = sub - t0;
end

