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
        meanSignal = mean(rawPhotodiode);
        maxSignal = meanSignal+3*std(rawPhotodiode);
        minSignal = meanSignal-1*std(rawPhotodiode);
    else
        rawPhotodiode = [];
        meanSignal = 0;
        maxSignal = 1;
        minSignal = -1;
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
suptitle(fileName);

% Raw photodiode plot
legenditems = {};
subplot(10,1,[1:7]);
hold on;
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
    
    plot(time, rawPhotodiode(tStart:tEnd), 'LineWidth', 0.25);
end
axis tight
ylim([minSignal maxSignal]);
xticks([]);
ylabel('Photodiode signal (mV)');
set(gca, 'FontSize', 6);
box off

% Photodiode marks
subplot(10,1,8);
hold on;
if ~isempty(photodiode)
    plot(photodiode(1:2:end),...
        ones(length(photodiode(1:2:end)),1),...
        'm.', 'MarkerSize', 3);
    plot(photodiode(2:2:end),...
        zeros(length(photodiode(2:2:end)),1),...
        'r.', 'MarkerSize', 3);
end
axis tight
ylim([-1 2]);
box off;
xticks([])
yticks([]);
ylabel('photo')
set(gca, 'FontSize', 6);

% Parallel marks
subplot(10,1,9);
hold on;
if ~isempty(parallel)
    plot(parallel(1:2:end),...
        ones(length(parallel(1:2:end)),1),...
        'm.', 'MarkerSize', 3);
    plot(parallel(2:2:end),...
        zeros(length(parallel(2:2:end)),1),...
        'r.', 'MarkerSize', 3);
end
axis tight
ylim([-1 2]);
box off;
xticks([])
yticks([]);
ylabel('parallel')
set(gca, 'FontSize', 6);

% Matlab marks
subplot(10,1,10);
hold on;
if ~isempty(matlab)
    plot(matlab,...
        zeros(length(matlab),1),...
        'm.', 'MarkerSize', 3);
    legenditems = 'matlab';
end
axis tight
ylim([-1 1]);
box off;
xlabel('Time (s)');
yticks([]);
ylabel('matlab')
set(gca, 'FontSize', 6);


% Legend depends on what is present



resultsDir = fullfile(resultsPath, 'StimTimes');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

saveas(gcf, fullfile(resultsDir, [fileName, '_stimtimes.png']));
saveas(gcf, fullfile(resultsDir, [fileName, '_stimtimes']), 'fig');

close(gcf)

end

