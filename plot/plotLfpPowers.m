function nf = plotLfpPowers(nf, ex, data, fs, time, varargin)
%plotLfp Draw a per-condition plot of LFP data
%
% delta 0-4hz
% theta 4-8hz
% alpha 8-13hz
% beta 13-25hz
% low gamma 25-55hz
% high gamma 55-120hz

binSize = 5*fs; % 5 seconds of data in each bin
nBins = floor(length(data)/binSize);

truncate = rem(length(data),nBins);
data = data(1:end-truncate);

x = linspace(0, length(data)/fs, nBins);

data = reshape(data, length(data)/nBins, nBins);

[Y, f] = spectrum(data, fs);

freqs = [0, 4; 4, 8; 8, 13; 13, 25; 25, 55; 55, 120];

hold on;
for i = 1:size(freqs,1)
    plot(x, smooth(sum(Y(f>= freqs(i,1) & f < freqs(i, 2),:))));
end

axis tight
legend({'delta';'theta';'alpha';'beta';'low gamma';'high gamma'},...
                'Location','northwest','FontSize',6);
legend boxoff
xlabel('time [s]')
ylabel('Power');

nf.suffix = 'lfp_power';
nf.dress();