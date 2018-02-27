function [m] = mfr(spikes, t0, t1)
%MRF mean firing rate of spikes
m = length(spikeTimes(spikes, t0, t1)) / (t1 - t0);
end

