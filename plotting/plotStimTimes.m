function plotStimTimes( dataPath, resultsPath, fileName )
%plotStimTimes Visualize stim times

filePath = fullfile(dataPath, [fileName, '-export.mat']);
if exist(filePath, 'file')
    load(filePath);
else
    return;
end

% Collect all stim times
if exist('Ripple', 'var') && isfield(Ripple, 'Events')
    StimTimes = Ripple.Events.StimTimes;
    photodiode = StimTimes.photodiode;
    if ~isempty(photodiode)
        Analog = Ripple.AnalogIn.Channels(strcmp(Ripple.AnalogIn.Channels.name, ...
            'analog 1'),:);
        rawPhotodiode = Analog.data{1};
        maxSignal = max(rawPhotodiode);
    else
        rawPhotodiode = [];
        maxSignal = 1;
    end
    parallel = StimTimes.parallel;
else
    photodiode = [];
    parallel = [];
end
if exist('Params', 'var') && isfield(Params, 'Data')
    matlab = Params.Data.stimTime;
else
    matlab = [];
end

figure('Visible', 'off')
hold on;



% Plot everything
legenditems = {};

if ~isempty(rawPhotodiode) 
    % Determine sample rate, tstart, and tend
    fs = Ripple.AnalogIn.sampleRate;
    if photodiode(1) > 0
        tStart = ceil(photodiode(1)*fs);
    else
        tStart = 1;
    end
    tEnd = length(rawPhotodiode);
    time = (tStart:tEnd)./fs;
    plot(time, rawPhotodiode(tStart:tEnd));
    legenditems = [legenditems, 'raw'];
end
if ~isempty(photodiode)
    plot(photodiode(1:2:end),maxSignal/3*2*ones(length(photodiode(1:2:end)),1),'ro');
    plot(photodiode(2:2:end),maxSignal/3*1.8*ones(length(photodiode(2:2:end)),1),'ko');
    legenditems = [legenditems, {'photodiode on', 'photodiode off'}];
end
if ~isempty(parallel)
    plot(parallel(1:2:end),maxSignal/3*ones(length(parallel(1:2:end)),1),'bs');
    plot(parallel(2:2:end),maxSignal/3.2*ones(length(parallel(2:2:end)),1),'gs');
    legenditems = [legenditems, {'parallel on', 'parallel off'}];
end
if ~isempty(matlab)
    plot(matlab,maxSignal/2*ones(length(matlab),1),'ms');
    legenditems = [legenditems, 'matlab'];
end
hold off;
axis tight;

% Legend depends on what is present
legend(legenditems);

title(fileName);

resultsDir = fullfile(resultsPath, 'StimTimes');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

saveas(gcf, fullfile(resultsDir, [fileName, '_stimtimes.png']));
saveas(gcf, fullfile(resultsDir, [fileName, '_stimtimes']), 'fig');

close(gcf)

end

