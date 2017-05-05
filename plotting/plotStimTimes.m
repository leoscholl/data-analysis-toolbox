function plotStimTimes( dataPath, fileName )
%plotStimTimes Visualize stim times

filePath = fullfile(dataPath, [fileName, '-export.mat']);
load(filePath);

StimTimes = Ripple.Events.StimTimes;
Analog = Ripple.AnalogIn.Channels(strcmp(Ripple.AnalogIn.Channels.name, ...
    'analog 1'),:);
rawPhotodiode = Analog.data{1};
maxSignal = max(rawPhotodiode);
photodiode = StimTimes.photodiode;
parallel = StimTimes.parallel;
matlab = Params.Data.stimTime;

timeFrom = 0.5;
fs = Ripple.AnalogIn.sampleRate;
tStart = 1; %round((photodiode(1) - timeFrom)*fs);
tEnd = length(rawPhotodiode); round((photodiode(end) + timeFrom)*fs);

time = (tStart:tEnd)./fs;
figure
hold on;
plot(time, rawPhotodiode(tStart:tEnd));
plot(photodiode(1:2:end),maxSignal/3*2*ones(length(photodiode(1:2:end)),1),'ro');
plot(photodiode(2:2:end),maxSignal/3*1.8*ones(length(photodiode(2:2:end)),1),'ko');
plot(parallel(1:2:end),maxSignal/3*ones(length(parallel(1:2:end)),1),'bs');
plot(parallel(2:2:end),maxSignal/3.2*ones(length(parallel(2:2:end)),1),'gs');
plot(matlab,maxSignal/2*ones(length(matlab),1),'ms');
hold off;
axis tight;



legend({'raw','photodiode on','photodiode off','parallel on', 'parallel off', 'matlab'});

end

