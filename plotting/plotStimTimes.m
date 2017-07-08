function plotStimTimes( StimTimes, AnalogIn, figuresPath, fileName, errorMsg )
%plotStimTimes Visualize stim times

%% Collect all stim times
rawPhotodiode = [];
photodiode = [];
parallel = [];
matlab = [];
meanSignal = 0;
maxSignal = 1;
minSignal = -1;

% Photodiode
if isfield(StimTimes, 'photodiode') && ~isempty(StimTimes.photodiode)
    photodiode = StimTimes.photodiode;
    if ~isempty(photodiode)
        Analog = AnalogIn.Channels(strcmp(AnalogIn.Channels.name, ...
            'analog 1'),:);
        if ~isempty(Analog) && isfield(Analog, 'data') && ...
                ~isempty(Analog.data)
            rawPhotodiode = Analog.data{1};
            fs = AnalogIn.sampleRate;
            meanSignal = mean(rawPhotodiode);
            maxSignal = meanSignal+3*std(rawPhotodiode);
            minSignal = meanSignal-1*std(rawPhotodiode);
        end
    end
end

% Parallel
if isfield(StimTimes, 'parallel') && ~isempty(StimTimes.parallel)
    parallel = StimTimes.parallel;
end

% PTB
if isfield(StimTimes, 'matlab')
    matlab = StimTimes.matlab;
end

%% Plotting
fig = figure('Visible', 'off');
suptitle(fileName);

% Raw photodiode plot
subplot(10,1,[1:6]);
hold on;
if ~isempty(rawPhotodiode)
    % Determine sample rate, tstart, and tend
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


% Text box with error message
dim = [0.125 0.33 0.75 0.1];
annotation('textbox',dim,'String',errorMsg,'FitBoxToText','off', ...
    'FontSize', 6, 'Color', 'r', 'LineStyle', 'none');


figureDir = fullfile(figuresPath, 'StimTimes');
if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end

saveas(fig, fullfile(figureDir, [fileName, '_stimtimes.png']));
saveas(fig, fullfile(figureDir, [fileName, '_stimtimes']), 'fig');

close(fig)

end

