function plotLfpPowers(data, fs)
%plotLfp Draw a per-condition plot of LFP data
%
% delta 0-4hz
% theta 4-8hz
% alpha 8-13hz
% beta 13-25hz
% low gamma 25-55hz
% high gamma 55-120hz

window = min(5*fs, length(data));
noverlap = fs;
freqs = [0, 4; 4, 8; 8, 13; 13, 25; 25, 55; 55, 120];
f = 0:0.5:120;
[s,f,t] = spectrogram(data,window,noverlap,f,fs);
hold on;
for i = 1:size(freqs,1)
    plot(t, mean(abs(s(f>= freqs(i,1) & f < freqs(i, 2),:)).^2));
end

set(gca,'YScale','log')
axis tight
legend({'delta (0-4 Hz)';'theta (4-8 Hz)';'alpha (8-13 Hz)';'beta (13-25 Hz)';...
    'low gamma (25-55 Hz)';'high gamma'},...
                'Location','northwest','FontSize',6);
legend boxoff
xlabel('time [s]')
ylabel('Power');

