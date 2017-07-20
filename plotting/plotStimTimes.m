function plotStimTimes( StimTimes, dataset, figuresPath, fileName )
%plotStimTimes Visualize stim times

%% Collect all stim times
rawPhotodiode = [];
photodiode = [];
parallel = [];
matlab = [];
meanSignal = 0;
maxSignal = 1;
minSignal = -1;
tStart = Inf;
tEnd = 0;

% Photodiode
if isfield(StimTimes, 'photodiode') && ~isempty(StimTimes.photodiode)
    photodiode = StimTimes.photodiode;
    if ~isempty(photodiode) && isfield(dataset, 'analog1k')
        fs = dataset.analog1k.fs;
        rawPhotodiode = dataset.analog1k.data(:,dataset.analog1k.electrodeid == 10241)';
        meanSignal = mean(rawPhotodiode);
        maxSignal = meanSignal+3*std(rawPhotodiode);
        minSignal = meanSignal-1*std(rawPhotodiode);
    end
    tStart = min(tStart, photodiode(1));
    tEnd = max(tEnd, photodiode(end));
end

% Parallel
if isfield(StimTimes, 'parallel') && ~isempty(StimTimes.parallel)
    parallel = StimTimes.parallel;
    tStart = min(tStart, parallel(1));
    tEnd = max(tEnd, parallel(end));
end

% PTB
if isfield(StimTimes, 'matlab')
    matlab = StimTimes.matlab;
    tStart = min(tStart, matlab(1));
    tEnd = max(tEnd, matlab(end));
end

%% Plotting
fig = figure('Visible', 'off');
suptitle(fileName);

% Raw photodiode plot
subplot(10,1,[1:6]);
hold on;
if ~isempty(rawPhotodiode)
    ptStart = max(ceil((tStart - dataset.analog1k.time(1))*fs), 0);
    ptEnd = min(ceil((tEnd - dataset.analog1k.time(1))*fs), length(rawPhotodiode));
    time = (ptStart:ptEnd)./fs;
    plot(time, rawPhotodiode(ptStart:ptEnd), 'LineWidth', 0.25);
end
xticks([])
xlim([tStart-1 tEnd]);
ylim([minSignal maxSignal]);
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
ylim([-1 2]);
xlim([tStart-1 tEnd]);
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
ylim([-1 2]);
xlim([tStart-1 tEnd]);
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
ylim([-1 1]);
xlim([tStart-1 tEnd]);
box off;
xlabel('Time (s)');
yticks([]);
ylabel('matlab')
set(gca, 'FontSize', 6);


% Text box with error message
dim = [0.125 0.33 0.75 0.1];
annotation('textbox',dim,'String',StimTimes.msg,'FitBoxToText','off', ...
    'FontSize', 6, 'Color', 'r', 'LineStyle', 'none');


figureDir = fullfile(figuresPath, 'StimTimes');
if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end

saveas(fig, fullfile(figureDir, [fileName, '_stimtimes.png']));
saveas(fig, fullfile(figureDir, [fileName, '_stimtimes']), 'fig');

close(fig)

end

