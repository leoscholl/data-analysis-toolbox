function plotLfpPowers(data, fs)
%plotLfp Draw a per-condition plot of LFP data
%
% delta 0-4hz
% theta 4-8hz
% alpha 8-13hz
% beta 13-25hz
% low gamma 25-55hz
% high gamma 55-120hz

freqs = [1, 4; 4, 8; 8, 13; 13, 25; 25, 55; 55, 120];
   
targetfs = 300;
if fs > targetfs
    oldfs = fs;
    data = data(1:round(oldfs/targetfs):end);
    fs = oldfs/round(oldfs/targetfs);
end

k = round(60*fs);
t = linspace(0, length(data)/fs/60, length(data));
y = zeros(size(freqs,1),length(data));
for i = 1:size(freqs,1)
    [b,a]=butter(4,freqs(i,:)/(fs/2));
    bp = filtfilt(b,a,data);
    y(i,:) = movmean(abs(hilbert(bp)),k);
end

plot(t, y);

axis tight
set(gca, 'CameraUpVector', [1 0 0]);
legend({'delta (0-4 Hz)';'theta (4-8 Hz)';'alpha (8-13 Hz)';'beta (13-25 Hz)';...
    'low gamma (25-55 Hz)';'high gamma'},...
                'Location','northwest','FontSize',6);
legend boxoff
xlabel('time [min]')
ylabel('Power');

