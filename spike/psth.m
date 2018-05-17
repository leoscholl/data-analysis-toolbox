function [hist] = psth(spikes, t0, t1, nBins, normFun)
%PSTH for a single spike vector
hist = zeros(1,nBins);
spikesSub = spikeTimes(spikes, t0, t1);
edges = 0:(t1-t0)/(nBins):(t1-t0);
if ~isempty(spikesSub)
    hist = histcounts(spikesSub,edges);
    if exist('normFun', 'var') && ~isempty(normFun)
        hist = normFun(hist);
    end
end
end

